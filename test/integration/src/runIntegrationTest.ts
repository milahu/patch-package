//const debugTests = true // print output of *.sh test scripts, keep temporary files
const debugTests = false

// TODO optimize: avoid "yarn install". use one project folder, use git to rollback state
// TODO optimize: use smaller test packages (synthetic tests), smaller than left-pad etc

import * as fs from "fs-extra"
import { join } from "../src/path"
import * as tmp from "tmp"
import { spawnSafeSync } from "../src/spawnSafe"
import { resolveRelativeFileDependencies } from "../src/resolveRelativeFileDependencies"

// these env-vars are set in run-tests.sh
export const patchPackageTarballPath = process.env['PATCH_PACKAGE_TGZ'] || ''
const patchPackageBin = process.env['PATCH_PACKAGE_BIN'] || ''
const bashprofAnalyzeBin = process.env['BASHPROF_ANALYZE_BIN'] || ''

export function runIntegrationTest({
  projectName,
  shouldProduceSnapshots,
}: {
  projectName: string
  shouldProduceSnapshots: boolean
}) {
  describe(`Test ${projectName}:`, () => {
    const tmpDir = tmp.dirSync({
      unsafeCleanup: true,
      prefix: `patch-package.test-integration.${projectName}.`,
    })
    fs.copySync(join(__dirname, projectName), tmpDir.name, {
      recursive: true,
    })

    const packageJson = require(join(tmpDir.name, "package.json"))
    packageJson.dependencies = resolveRelativeFileDependencies(
      join(__dirname, projectName),
      packageJson.dependencies,
    )

    fs.writeFileSync(
      join(tmpDir.name, "package.json"),
      JSON.stringify(packageJson),
    )

    const enableBashProfiling = false
    if (enableBashProfiling && debugTests) {
      // add bash profiling code
      //console.log(`( cd ${tmpDir.name} && ./${projectName}.sh ${patchPackageTarballPath} )`)

      // https://stackoverflow.com/questions/5014823/how-can-i-profile-a-bash-shell-script-slow-startup
      const scriptHeader = [
        "#! /usr/bin/env bash",
        "echo bashprof: writing /tmp/bashprof-$$.log and /tmp/bashprof-$$.tim",
        "exec 3>&2 2> >(",
        "  tee /tmp/bashprof-$$.log |",
        "  sed -u 's/^.*$/now/' |",
        "  date -f - +%s.%N >/tmp/bashprof-$$.tim",
        ")",
        "set -x",
        "# rest of your script ...",
      ].join("\n") + "\n\n"

      const scriptBody = fs.readFileSync(
        `${tmpDir.name}/${projectName}.sh`,
        'utf8'
      )

      fs.writeFileSync(
        `${tmpDir.name}/${projectName}.sh`,
        (scriptHeader + scriptBody),
        'utf8'
      )
    }


    // patch the script
    // TODO apply to files in git
    if (debugTests) {
      console.log(`patching test script: ${tmpDir.name}/${projectName}.sh`)
      console.log(`patching test script: patchPackageBin = ${patchPackageBin}`)
    }
    var scriptBody = fs.readFileSync(
      `${tmpDir.name}/${projectName}.sh`,
      'utf8'
    )
    if (scriptBody.match(/node_modules\/patch-package/)) {
      // slow: we need a local install of patch-package
      // to force local install, add this to test script:
      //   stat node_modules/patch-package # force local install in runIntegrationTest.ts
    }
    else {
      // fast: use global install of patch-package
      const aliasCmd = `alias patch-package="node ${patchPackageBin}"`;
      scriptBody = scriptBody
      //.replace(/^(yarn add \$1)$/m, `# $1`)
      .replace(/^(yarn add \$1.*?)$/m, `yarn install\n${aliasCmd}\n`)
      // yarn add $1
      // yarn add $1 --ignore-workspace-root-check
      .replace(/^alias patch-package="npx patch-package"$/m, aliasCmd)
      .replace(/^(yarn|npx) patch-package$/m, `patch-package`)
      // sed is faster than "npx replace"
      //.replace(/^(yarn|npx) replace ([^ ]+) ([^ ]+) /m, `sed -i 's,$1,$2,' `) // TODO verify
      // sed -i 's/leftPad/patch-package/' node_modules/left-pad/index.js
      // sed -i 's/leftPad/patchPackage/' node_modules/left-pad/index.js
    }

    scriptBody = [
      '#! /usr/bin/env bash',
      'shopt -s expand_aliases # enable alias',
    ].join('\n') + '\n' + scriptBody

    fs.writeFileSync(
      `${tmpDir.name}/${projectName}.sh`,
      scriptBody,
      'utf8'
    )

    const result = spawnSafeSync(
      `./${projectName}.sh`,
      [
        patchPackageTarballPath // needed for local install of patch-package
      ],
      {
        cwd: tmpDir.name,
        throwOnError: false,
      },
    )

    it("should exit with 0 status", () => {
      expect(result.status).toBe(0)
    })

    const output = result.stdout.toString() + "\n" + result.stderr.toString()
    // TODO correctly interleave stdout and stderr -> use execa library

    if (result.status !== 0) {
      console.error(output)
    }

    if (debugTests) {
      // print timings
      const timFileMatch = output.match(/^bashprof: writing (.*?-[0-9]+\.log) and (.*?-[0-9]+\.tim)/)
      if (!timFileMatch) {
        console.log(`internal error: failed to parse bashprof output in output: ${output}`)
      } else {
        const logFile = timFileMatch[1]
        console.log(`${bashprofAnalyzeBin} ${logFile} )`)
        const resultBashprof = spawnSafeSync(
          bashprofAnalyzeBin,
          [logFile],
          { throwOnError: false },
        )
        console.log("bashprof timings:")
        console.log(resultBashprof.stdout.toString())
      }
    }

    it("should produce output", () => {
      expect(output.trim()).toBeTruthy()
    })

    const snapshots = output.match(/SNAPSHOT: ?([\s\S]*?)END SNAPSHOT/g)

    if (shouldProduceSnapshots) {
      it("should produce some snapshots", () => {
        expect(snapshots && snapshots.length).toBeTruthy()
      })
      if (snapshots) {
        snapshots.forEach((snapshot) => {
          const snapshotDescriptionMatch = snapshot.match(/SNAPSHOT: (.*)/)
          if (debugTests) {
            console.log(`snapshot: ${snapshot}`)
          }
          if (snapshotDescriptionMatch) {
            it(snapshotDescriptionMatch[1], () => {
              if (debugTests) {
                console.log(`snapshotDescriptionMatch[1]: ${snapshotDescriptionMatch[1]}`)
              }
              expect(snapshot).toMatchSnapshot()
            })
          } else {
            throw new Error("bad snapshot format")
          }
        })
      }
    } else {
      it("should not produce any snapshots", () => {
        expect(snapshots && snapshots.length).toBeFalsy()
      })
    }

    if (debugTests) {
      console.log(`keeping temporary files: ${tmpDir.name}`)
    }
    else {
      tmpDir.removeCallback()
    }
  })
}

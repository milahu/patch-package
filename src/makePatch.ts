import chalk from "chalk"
import { join, dirname, resolve } from "./path"
import { spawnSafeSync } from "./spawnSafe"
import { PackageManager } from "./detectPackageManager"
import { removeIgnoredFiles } from "./filterFiles"
import {
  writeFileSync,
  existsSync,
  mkdirSync,
  unlinkSync,
  mkdirpSync,
  realpathSync,
  renameSync,
} from "fs-extra"
import { sync as rimraf } from "rimraf"
import { copySync } from "fs-extra"
import { dirSync } from "tmp"
import { getPatchFiles } from "./patchFs"
import {
  getPatchDetailsFromCliString,
  getPackageDetailsFromPatchFilename,
  PackageDetails,
} from "./PackageDetails"
import { resolveRelativeFileDependencies } from "./resolveRelativeFileDependencies"
import { getPackageResolution } from "./getPackageResolution"
import { parsePatchFile } from "./patch/parse"
import { gzipSync } from "zlib"
import { getPackageVersion } from "./getPackageVersion"
import {
  maybePrintIssueCreationPrompt,
  openIssueCreationLink,
} from "./createIssue"
import { spawnSync } from "child_process"

// globals are set in src/index.ts
const isVerbose = global.patchPackageIsVerbose
const isDebug = global.patchPackageIsDebug
const patchPackageVersion = global.patchPackageVersion

function printNoPackageFoundError(
  packageName: string,
  packageJsonPath: string,
) {
  console.error(
    `No such package ${packageName}

  File not found: ${packageJsonPath}`,
  )
}

export function makePatch({
  packagePathSpecifier,
  appPath,
  packageManager,
  includePaths,
  excludePaths,
  patchDir,
  createIssue,
}: {
  packagePathSpecifier: string
  appPath: string
  packageManager: PackageManager
  includePaths: RegExp
  excludePaths: RegExp
  patchDir: string
  createIssue: boolean
}) {
  const packageDetails = getPatchDetailsFromCliString(packagePathSpecifier)

  if (!packageDetails) {
    console.error("No such package", packagePathSpecifier)
    return
  }
  const appPackageJson = require(join(appPath, "package.json"))
  const packagePath = join(appPath, packageDetails.path)
  const packageJsonPath = join(packagePath, "package.json")

  if (isDebug) {
    console.log(`patch-package/makePatch: appPath = ${appPath}`)
    console.log(`patch-package/makePatch: packagePath = ${packagePath}`)
    console.log(`patch-package/makePatch: appPackageJson:`)
    console.dir(appPackageJson)
  }

  if (!existsSync(packageJsonPath)) {
    printNoPackageFoundError(packagePathSpecifier, packageJsonPath)
    process.exit(1)
  }

  const tmpRepo = dirSync({
    unsafeCleanup: true,
    prefix: "patch-package.tmpRepo.",
  })

  function cleanup() {
    if (isDebug) {
      console.log(`patch-package/makePatch: cleanup: keeping temporary files: ${tmpRepo.name}`)
      return
    }
    tmpRepo.removeCallback()
  }

  try {
    // finally: cleanup()

    const tmpRepoPackagePath = join(tmpRepo.name, packageDetails.path)
    const tmpRepoNpmRoot = tmpRepoPackagePath.slice(
      0,
      -`/node_modules/${packageDetails.name}`.length,
    )

    const tmpRepoPackageJsonPath = join(tmpRepoNpmRoot, "package.json")

    const patchesDir = resolve(join(appPath, patchDir))

    console.info(chalk.grey("•"), "Creating temporary folder")

    if (isDebug) {
      console.log(
        `patch-package/makePatch: tmpRepoNpmRoot = ${tmpRepoNpmRoot}`,
      )
    }

    const resolvedVersion = getPackageResolution({
      packageDetails,
      packageManager,
      appPath,
      appPackageJson,
    })

    // make a blank package.json
    mkdirpSync(tmpRepoNpmRoot)
    writeFileSync(
      tmpRepoPackageJsonPath,
      JSON.stringify({
        dependencies: {
          [packageDetails.name]: resolvedVersion.version,
        },
        resolutions: resolveRelativeFileDependencies(
          appPath,
          appPackageJson.resolutions || {},
        ),
      }),
    )

    const declaredVersion = (() => {
      var v = resolvedVersion.version
      // https://docs.npmjs.com/cli/v7/configuring-npm/package-json
      // <protocol>://[<user>[:<password>]@]<hostname>[:<port>][:][/]<path>[#<commit-ish> | #semver:<semver>]
      // pnpm uses link: protocol instead of file:
      // TODO add more protocols?
      var m = v.match(/^(file|link|http|https|git|git\+https|git\+http|git\+ssh|git\+file|github):(.+)$/)
      if (m) {
        var protocol = m[1]
        var location = m[2]
        var isGit = protocol.startsWith('git')
        var gitCommit = (isGit && location.includes("#")) ? location.split('#').slice(-1)[0] : null
        if (isDebug) {
          console.dir({ loc: 'get declaredVersion', isGit, gitCommit });
        }
        if (isGit && !gitCommit) {
          var error = new Error(`found wildcard git version ${v}. \
package.json must pin the exact version of ${packageDetails.name} \
in the format <protocol>:<packagePath>#<commitHash>. \
commitHash is the full hash with 40 chars.`)
          delete error.stack
          throw error
          /* too complex
          // guess commit hash of installed package
          var stats = lstatSync(packageDetails.path)
          if (stats.isSymbolicLink()) {
            var linkTarget = readlinkSync(packageDetails.path)
            if (linkTarget.startsWith(".pnpm")) {
              var match = linkTarget.match(/^\.pnpm\/[^/]+@([0-9a-f]{10})_[0-9a-f]{32}\//)
              if (match) {
                gitCommit = match[1]
                if (isDebug) console.log(`parsed gitCommit ${gitCommit} from pnpm symlink`)
              }
            }
          }
          */
        }
        if (isGit) {
          return { full: v, protocol, location, gitCommit }
        }
        else {
          // sample: https://registry.yarnpkg.com/left-pad/-/left-pad-1.3.0.tgz#5b8a3a7765dfe001261dde915589e782f8c94d1e
          // hash is sha1sum of tgz file
          // -> use version number from package's package.json
          var version = getPackageVersion(join(resolve(packageDetails.path), "package.json"))
          if (isVerbose) {
            console.log(`patch-package/makePatch: using version ${version} from ${packageDetails.name}/package.json`)
          }
          return { version }
        }
      }
      // https://docs.npmjs.com/about-semantic-versioning
      // TODO handle protocols? pnpm workspace: protocol does not make sense here, no need to patch local packages
      var m = v.match(/^([~^])(.*)$/)
      if (m) {
        var exampleVersion = m[1]
        if (!exampleVersion) {
          exampleVersion = '1.0.0'
        }
        console.warn(`patch-package/makePatch: warning: found wildcard version ${v}. \
to ensure successful patching, package.json should pin the exact version of ${packageDetails.name} \
in the format <major>.<minor>.<patch>, for example: "${packageDetails.name}": "${exampleVersion}"`)
      }
      return { full: v, version: v }
    })()

    if (isDebug) {
      //console.log(`patch-package/makePatch: resolvedVersion.originCommit = ${resolvedVersion.originCommit}`)
      console.log(`patch-package/makePatch: declaredVersion.version = ${declaredVersion.version}`)
      console.log(`patch-package/makePatch: declaredVersion.gitCommit = ${declaredVersion.gitCommit}`)
      console.log(`patch-package/makePatch: declaredVersion.full = ${declaredVersion.full}`)
    }

    const packageVersion = (
      declaredVersion.version || declaredVersion.gitCommit || declaredVersion.full
    )

    // originCommit is more precise than pkg.version
    if (isDebug) {
      //console.log(`patch-package/makePatch: resolvedVersion.originCommit = ${resolvedVersion.originCommit}`)
      console.log(`patch-package/makePatch: resolvedVersion.version = ${resolvedVersion.version}`)
      console.log(`patch-package/makePatch: packageVersion = ${packageVersion}`)
    }

    //const packageVersion =
    //  resolvedVersion.originCommit ||
    //  getPackageVersion(join(resolve(packageDetails.path), "package.json"))

    // this is broken when installing from git -> version can be a pseudo-version like 1.0.0-canary
    //const packageVersion = getPackageVersion(join(resolve(packageDetails.path), "package.json"))

    // TODO rename resolvedVersion -> declaredVersion

    // FIXME false positive
    // test integration-tests/create-issue/create-issue.test.ts
    // -> patching left-pad prompts to submit an issue
    // https://registry.yarnpkg.com/left-pad/-/left-pad-1.3.0.tgz#5b8a3a7765dfe001261dde915589e782f8c94d1e
    // hash is sha checksum of tgz file -> just use the version 1.3.0
    /*
    const packageVersion = (
      !resolvedVersion.version.match(/^(file:|link:)/) ? resolvedVersion.version :
      getPackageVersion(join(resolve(packageDetails.path), "package.json"))
    )
    */

    if (isDebug) {
      console.log(`patch-package/makePatch: getPackageVersion -> ${getPackageVersion(join(resolve(packageDetails.path), "package.json"))}`)
      console.log(`patch-package/makePatch: package path = ${packageDetails.path}`)
      console.log(`patch-package/makePatch: package path resolved = ${resolve(packageDetails.path)}`)
    }

    // copy .npmrc/.yarnrc in case packages are hosted in private registry
    // tslint:disable-next-line:align
    ;[".npmrc", ".yarnrc"].forEach((rcFile) => {
      const rcPath = join(appPath, rcFile)
      if (existsSync(rcPath)) {
        copySync(rcPath, join(tmpRepo.name, rcFile))
      }
    })

    if (packageManager === "yarn") {
      console.info(
        chalk.grey("•"),
        `Installing ${packageDetails.name}@${packageVersion} with yarn`,
      )
      try {
        // try first without ignoring scripts in case they are required
        // this works in 99.99% of cases
        spawnSafeSync(`yarn`, ["install", "--ignore-engines"], {
          cwd: tmpRepoNpmRoot,
          logStdErrOnError: false,
        })
      } catch (e: any) {
        // try again while ignoring scripts in case the script depends on
        // an implicit context which we havn't reproduced
        spawnSafeSync(
          `yarn`,
          ["install", "--ignore-engines", "--ignore-scripts"],
          {
            cwd: tmpRepoNpmRoot,
          },
        )
      }
    } else {
      const npmCmd = packageManager === "pnpm" ? "pnpm" : "npm"
      console.info(
        chalk.grey("•"),
        `Installing ${packageDetails.name}@${packageVersion} with ${npmCmd}`,
      )
      try {
        // try first without ignoring scripts in case they are required
        // this works in 99.99% of cases
        if (isVerbose) {
          console.log(
            `patch-package/makePatch: run "${npmCmd} install --force" in ${tmpRepoNpmRoot}`,
          )
        }
        spawnSafeSync(npmCmd, ["install", "--force"], {
          cwd: tmpRepoNpmRoot,
          logStdErrOnError: false,
          stdio: isVerbose ? "inherit" : "ignore",
        })
      } catch (e: any) {
        // try again while ignoring scripts in case the script depends on
        // an implicit context which we havn't reproduced
        if (isVerbose) {
          console.log(
            `patch-package/makePatch: run "${npmCmd} install --ignore-scripts --force" in ${tmpRepoNpmRoot}`,
          )
        }
        spawnSafeSync(npmCmd, ["install", "--ignore-scripts", "--force"], {
          cwd: tmpRepoNpmRoot,
          stdio: isVerbose ? "inherit" : "ignore",
        })
      }
      if (packageManager === "pnpm") {
        // workaround for `git diff`: replace symlink with hardlink
        const pkgPath = tmpRepoNpmRoot + "/node_modules/" + packageDetails.name
        const realPath = realpathSync(pkgPath)
        unlinkSync(pkgPath) // rm symlink
        renameSync(realPath, pkgPath)
      }
    }

    function git(...args: string[]) {
      if (isDebug) {
        const argsStr = JSON.stringify(["git", ...args])
        console.log(`patch-package/makePatch: spawn: args = ${argsStr} + workdir = ${tmpRepo.name}`)
      }
      return spawnSafeSync("git", args, {
        cwd: tmpRepo.name,
        env: { ...process.env, HOME: tmpRepo.name },
        maxBuffer: 1024 * 1024 * 100,
      })
    }

    // remove nested node_modules just to be safe
    rimraf(join(tmpRepoPackagePath, "node_modules"))
    // remove .git just to be safe
    rimraf(join(tmpRepoPackagePath, ".git"))

    // commit the package
    console.info(chalk.grey("•"), "Diffing your files with clean files")
    writeFileSync(join(tmpRepo.name, ".gitignore"), "!/node_modules\n\n")
    git("-c", "init.defaultBranch=main", "init")

    // remove ignored files first
    // use CLI options --exclude and --include
    removeIgnoredFiles(tmpRepoPackagePath, includePaths, excludePaths)

    git("add", "-f", packageDetails.path)
    if (isVerbose) {
      console.log(`git status:\n` + git("status").stdout.toString())
    }
    git("-c", "user.name=patch-package", "-c", "user.email=", "commit", "--allow-empty", "-m", "init")

    // replace package with user's version
    if (isVerbose) {
      console.log(`patch-package/makePatch: remove all files in ${tmpRepoPackagePath}`)
    }
    rimraf(tmpRepoPackagePath)

    if (isVerbose) {
      console.log(`patch-package/makePatch: git status:\n` + git("status").stdout.toString())
    }

    // pnpm installs packages as symlinks, copySync would copy only the symlink
    // with pnpm, realpath resolves to ./node_modules/.pnpm/${name}@${version}
    const srcPath = realpathSync(packagePath)
    if (isVerbose) {
      console.log(
        `patch-package/makePatch: copy ${srcPath} to ${tmpRepoPackagePath} + skip ${srcPath}/node_modules/`,
      )
    }
    copySync(srcPath, tmpRepoPackagePath, {
      filter: (path) => {
        const doCopy = !path.startsWith(srcPath + "/node_modules/")
        if (isVerbose) {
          if (doCopy) {
            console.log(`patch-package/makePatch: copySync: copy file ${path}`)
          }
          else {
            console.log(`patch-package/makePatch: copySync: skip file ${path}`)
          }
        }
        return doCopy
      },
    })

    if (isDebug) {
      // list files
      // NOTE this works only on linux
      console.log(`patch-package/makePatch: files in srcPath = ${srcPath}`)
      console.log(spawnSync('find', ['.'], { cwd: srcPath, encoding: 'utf8' }).stdout)
      console.log(`patch-package/makePatch: files in tmpRepoPackagePath = ${tmpRepoPackagePath}`)
      console.log(spawnSync('find', ['.'], { cwd: tmpRepoPackagePath, encoding: 'utf8' }).stdout)
    }

    // remove nested node_modules just to be safe
    rimraf(join(tmpRepoPackagePath, "node_modules"))

    // remove .git just to be safe
    // NOTE this removes ./node_modules/${dependencyName}/.git not ./.git
    rimraf(join(tmpRepoPackagePath, ".git"))

    // also remove ignored files like before
    // for example, remove package.json
    // TODO support patching package.json via semantic json diff
    // use CLI options --exclude and --include

    if (isDebug) {
      console.log(`patch-package/makePatch: removing ignored files in tmpRepoPackagePath = ${tmpRepoPackagePath}:`)
    }
    removeIgnoredFiles(tmpRepoPackagePath, includePaths, excludePaths)

    if (isDebug) {
      // list files
      // NOTE this works only on linux
      console.log(`patch-package/makePatch: files in tmpRepoPackagePath = ${tmpRepoPackagePath}:`)
      console.log(spawnSync('find', ['.', '-type', 'f'], { cwd: tmpRepoPackagePath, encoding: 'utf8' }).stdout)
    }

    // stage all files
    git("add", "-f", packageDetails.path)

    if (isVerbose) {
      console.log(`patch-package/makePatch: git status:\n` + git("status").stdout.toString())
    }

    const ignorePaths = ["package-lock.json", "pnpm-lock.yaml"]

    // get diff of changes
    const diffResult = git(
      "diff",
      "--cached",
      "--no-color",
      "--ignore-space-at-eol",
      "--no-ext-diff",
      ...ignorePaths.map(
        (path) => `:(exclude,top)${packageDetails.path}/${path}`,
      ),
    )

    if (diffResult.stdout.length === 0) {
      console.warn(
        `⁉️  Not creating patch file for package '${packagePathSpecifier}'`,
      )
      console.warn(`⁉️  There don't appear to be any changes.`)
      cleanup()
      process.exit(1)
      return
    }

    try {
      parsePatchFile(diffResult.stdout.toString())
    } catch (e: any) {
      if (!(e instanceof Error)) return
      if (
        e.message.includes("Unexpected file mode string: 120000")
      ) {
        console.error(`
⛔️ ${chalk.red.bold("ERROR")}

  Your changes involve creating symlinks. patch-package does not yet support
  symlinks.
  
  ️Please use ${chalk.bold("--include")} and/or ${chalk.bold(
          "--exclude",
        )} to narrow the scope of your patch if
  this was unintentional.
`)
      } else {
        const outPath = "./patch-package-error.json.gz"
        writeFileSync(
          outPath,
          gzipSync(
            JSON.stringify({
              error: { message: e.message, stack: e.stack },
              patch: diffResult.stdout.toString(),
            }),
          ),
        )
        console.error(`
⛔️ ${chalk.red.bold("ERROR")}
        
  patch-package was unable to read the patch-file made by git. This should not
  happen.
  
  A diagnostic file was written to
  
    ${outPath}
  
  Please attach it to a github issue
  
    https://github.com/ds300/patch-package/issues/new?title=New+patch+parse+failed&body=Please+attach+the+diagnostic+file+by+dragging+it+into+here+🙏
  
  Note that this diagnostic file will contain code from the package you were
  attempting to patch.

`)
      }
      cleanup()
      process.exit(1)
      return
    }

    // maybe delete existing
    getPatchFiles(patchDir).forEach((filename) => {
      const deets = getPackageDetailsFromPatchFilename(filename)
      if (deets && deets.path === packageDetails.path) {
        unlinkSync(join(patchDir, filename))
      }
    })

    // patchfiles are parsed in patch/parse.ts function parsePatchLines
    // -> header comments are ignored
    let diffHeader = ""
    diffHeader += `# generated by patch-package ${patchPackageVersion}\n`
    diffHeader += `#\n`
    if (isDebug) {
      resolvedVersion.version
    }
    diffHeader += `# declared package:\n`
    diffHeader += `#   ${packageDetails.name}: ${resolvedVersion.declaredVersion}\n`
    // NOTE: we do *not* include the locked version from package-lock.json or yarn.lock or pnpm-lock.yaml or ...
    // because patch-package should work with all package managers (should be manager-agnostic)
    // users can pin versions in package.json
    diffHeader += `#\n`

    const patchFileName = createPatchFileName({
      packageDetails,
      packageVersion,
    })

    const patchPath = join(patchesDir, patchFileName)
    if (!existsSync(dirname(patchPath))) {
      mkdirSync(dirname(patchPath), { recursive: true })
    }
    writeFileSync(patchPath, diffHeader + diffResult.stdout)
    console.log(
      `${chalk.green("✔")} Created file ${join(patchDir, patchFileName)}\n`,
    )
    if (createIssue) {
      openIssueCreationLink({
        packageDetails,
        patchFileContents: diffResult.stdout.toString(),
        packageVersion,
      })
    } else {
      maybePrintIssueCreationPrompt(packageDetails, packageManager)
    }
  } catch (e: any) {
    //console.error(e)
    throw e
  } finally {
    cleanup()
  }
}

function createPatchFileName({
  packageDetails,
  packageVersion,
}: {
  packageDetails: PackageDetails
  packageVersion: string
}) {
  const packageNames = packageDetails.packageNames
    .map((name) => name.replace(/\//g, "+"))
    .join("++")

  return `${packageNames}+${packageVersion}.patch`
}

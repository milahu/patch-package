import fs from "fs-extra"
import { join } from "./path"
//import path from "path"
import chalk from "chalk"
import process from "process"
//import findYarnWorkspaceRoot from "find-yarn-workspace-root"

export type PackageManager = "yarn" | "npm" | "npm-shrinkwrap" | "pnpm"

//const isVerbose = global.patchPackageIsVerbose
const isDebug = global.patchPackageIsDebug

/*
function printNoYarnLockfileError() {
  console.error(`
${chalk.red.bold("**ERROR**")} ${chalk.red(
    `The --use-yarn option was specified but there is no yarn.lock file`,
  )}
`)
}
*/

function printNoLockfilesError() {
  console.error(`
${chalk.red.bold("**ERROR**")} ${chalk.red(
    `No package-lock.json, npm-shrinkwrap.json, or yarn.lock file.

You must use either npm@>=5, yarn, or npm-shrinkwrap to manage this project's
dependencies.`,
  )}
`)
}

/*
function printSelectingDefaultMessage() {
  console.info(
    `${chalk.bold(
      "patch-package",
    )}: you have both yarn.lock and package-lock.json
Defaulting to using ${chalk.bold("npm")}
You can override this setting by passing --use-yarn or deleting
package-lock.json if you don't need it
`,
  )
}
*/

/*
function isFileInPnpmRoot(rootPath: string, filename: string): boolean {
  const osRoot = path.parse(rootPath).root

  let currentDir = rootPath

  while (currentDir !== osRoot) {
    if (fs.existsSync(path.join(currentDir, "pnpm-workspace.yaml"))) {
      // Found workspace root. If the sought file is in the workspace root,
      // we're good.
      if (fs.existsSync(path.join(currentDir, filename))) {
        return true
      } else {
        return false
      }
    } else {
      currentDir = path.resolve(currentDir, "..")
    }
  }

  return false
}
*/

function pickManager(managersFound) {
  if (managersFound.includes("yarn")) return "yarn"
  if (managersFound.includes("pnpm")) return "pnpm"
  if (managersFound.includes("npm")) return "npm"
  return null
}

export const detectPackageManager = (
  appRootPath: string,
  overridePackageManager: PackageManager | null,
): PackageManager => {
  if (isDebug) {
    console.log(`patch-package/detectPackageManager:`)
    console.dir({
      appRootPath,
      overridePackageManager,
    })
  }

  const managerOfLockName = {
    'package-lock.json': 'npm',
    'npm-shrinkwrap.json': 'npm',
    'yarn.lock': 'yarn',
    'pnpm-lock.yaml': 'pnpm',
    'shrinkwrap.yaml': 'pnpm',
  }

  const pathParts = appRootPath.split("/")
  for (let depth = pathParts.length; depth > 0; depth--) {
      const workspaceCandidate = pathParts.slice(0, depth).join("/")
      if (isDebug) {
        console.log(`detectPackageManager: workspaceCandidate: ${workspaceCandidate}`)
      }
      // TODO fast path
      //if (overridePackageManager) {
      //  ...
      //}
      const lockfilesFound: string[] = (
        ([
          // TODO async
          ['package-lock.json', fs.existsSync(join(workspaceCandidate, "package-lock.json"))],
          ['npm-shrinkwrap.json', fs.existsSync(join(workspaceCandidate, "npm-shrinkwrap.json"))], // rare
          ['yarn.lock', fs.existsSync(join(workspaceCandidate, "yarn.lock"))],
          ['pnpm-lock.yaml', fs.existsSync(join(workspaceCandidate, "pnpm-lock.yaml"))],
          ['shrinkwrap.yaml', fs.existsSync(join(workspaceCandidate, "shrinkwrap.yaml"))], // rare
        ] as Array<[string, boolean]>)
        .filter(([_file, exists]) => exists)
        .map(([file, _exists]) => file)
      )
      if (isDebug) {
        console.log(`detectPackageManager: lockfilesFound: ${lockfilesFound.join(' ')}`)
      }
      if (lockfilesFound.length == 0) {
        continue
      }
      if (lockfilesFound.length == 1) {
        return managerOfLockName[lockfilesFound[0]]
      }
      // found multiple lockfiles
      const managersFound = lockfilesFound.map(file => managerOfLockName[file])
      if (overridePackageManager) {
        // TODO better. if overridePackageManager is set, we can skip some fs.existsSync calls
        if (managersFound.includes(overridePackageManager)) {
          return overridePackageManager
        }
        continue
      }
      const manager = pickManager(managersFound)
      if (manager) return manager
      // continue to parent folder
  }
  printNoLockfilesError();
  process.exit(1);
  /*
  const packageLockExists = fs.existsSync(
    join(appRootPath, "package-lock.json"), // npm
  )
  const shrinkWrapExists = fs.existsSync(
    join(appRootPath, "npm-shrinkwrap.json"), // old npm
  )
  const yarnLockExists = fs.existsSync(join(appRootPath, "yarn.lock"))
  const pnpmLockExists = fs.existsSync(
    join(appRootPath, "pnpm-lock.yaml"),
  )
  const oldPnpmLockExists = fs.existsSync(
    join(appRootPath, "shrinkwrap.yaml"), // old pnpm. lockfileVersion < 5
  )
  if (isDebug) {
    console.dir({
      packageLockExists,
      shrinkWrapExists,
      yarnLockExists,
      pnpmLockExists,
      oldPnpmLockExists,
    })
  }
  if ((packageLockExists || shrinkWrapExists) && yarnLockExists) {
    if (overridePackageManager) {
      return overridePackageManager
    } else {
      printSelectingDefaultMessage()
      return shrinkWrapExists ? "npm-shrinkwrap" : "npm"
    }
  } else if (packageLockExists || shrinkWrapExists) {
    if (overridePackageManager === "yarn") {
      printNoYarnLockfileError()
      process.exit(1)
    } else {
      return shrinkWrapExists ? "npm-shrinkwrap" : "npm"
    }
  } else if (yarnLockExists || findYarnWorkspaceRoot()) {
    return "yarn"
  } else if (isFileInPnpmRoot(appRootPath, "pnpm-lock.yaml")) {
    // (fs.existsSync(join(appRootPath, "pnpm-lock.yaml"))) {
    return "pnpm"
  } else {
    printNoLockfilesError()
    process.exit(1)
  }
  throw Error()
  */
}

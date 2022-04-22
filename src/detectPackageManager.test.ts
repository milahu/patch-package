//global.patchPackageIsDebug = true // debug

import { detectPackageManager } from "./detectPackageManager" // typescript

// FIXME test takes too long: 5 seconds

/*
import { join } from "./path"
import { normalize } from "path"
*/
//import { getPackageDetailsFromPatchFilename } from "./PackageDetails"
//import { existsSync } from "fs"

// https://www.emgoto.com/nodejs-mock-fs/
import mockFs from 'mock-fs'

//const appPath = normalize(join(__dirname, "../"))

const packageJsonContent = JSON.stringify({
  name: "test",
  version: "1.0.0",
})

function commonFiles() {
  // workaround for deep-clone of object
  const files = {
    workspaces: {
      workspace: {
        projects: {
          project: {
            "package.json": packageJsonContent,
          }
        }
      }
    }
  }
  return files
}

// workaround
// https://github.com/tschaub/mock-fs/issues/234
console.log('(workaround for mock-fs: fix console)')

describe('detectPackageManager', () => {

  let projectPath = "workspaces/workspace/projects/project"

  //beforeAll(() => {
  //  ...
  //})

  it("detects npm from lockfile in cwd", () => {
    const files = commonFiles()
    files.workspaces.workspace.projects.project["package-lock.json"] = "" // empty file is ok for now
    mockFs(files)
    expect(detectPackageManager(projectPath, null)).toBe("npm")
  })

  it("detects npm from lockfile in parent dir", () => {
    const files = commonFiles()
    files.workspaces.workspace.projects["package-lock.json"] = "" // empty file is ok for now
    mockFs(files)
    expect(detectPackageManager(projectPath, null)).toBe("npm")
  })

  it("detects npm from lockfile in parent dir 2", () => {
    const files = commonFiles()
    files.workspaces.workspace["package-lock.json"] = "" // empty file is ok for now
    mockFs(files)
    expect(detectPackageManager(projectPath, null)).toBe("npm")
  })

  it("detects yarn from lockfile in cwd", () => {
    const files = commonFiles()
    files.workspaces.workspace.projects.project["yarn.lock"] = "" // empty file is ok for now
    mockFs(files)
    expect(detectPackageManager(projectPath, null)).toBe("yarn")
  })

  it("detects yarn from lockfile in parent dir", () => {
    const files = commonFiles()
    files.workspaces.workspace.projects["yarn.lock"] = "" // empty file is ok for now
    mockFs(files)
    expect(detectPackageManager(projectPath, null)).toBe("yarn")
  })

  it("detects yarn from lockfile in parent dir 2", () => {
    const files = commonFiles()
    files.workspaces.workspace["yarn.lock"] = "" // empty file is ok for now
    mockFs(files)
    expect(detectPackageManager(projectPath, null)).toBe("yarn")
  })

  it("detects pnpm from lockfile in cwd", () => {
    const files = commonFiles()
    files.workspaces.workspace.projects.project["pnpm-lock.yaml"] = "" // empty file is ok for now
    mockFs(files)
    expect(detectPackageManager(projectPath, null)).toBe("pnpm")
  })

  it("detects pnpm from lockfile in parent dir", () => {
    const files = commonFiles()
    files.workspaces.workspace.projects["pnpm-lock.yaml"] = "" // empty file is ok for now
    mockFs(files)
    expect(detectPackageManager(projectPath, null)).toBe("pnpm")
  })

  it("detects pnpm from lockfile in parent dir 2", () => {
    const files = commonFiles()
    files.workspaces.workspace["pnpm-lock.yaml"] = "" // empty file is ok for now
    mockFs(files)
    expect(detectPackageManager(projectPath, null)).toBe("pnpm")
  })

  // FIXME
  /*
  it("falls back to npm if no lockfile was found", () => {
    const files = commonFiles()
    mockFs(files)
    expect(detectPackageManager(projectPath, null)).toBe("npm")
    mockFs.restore()
  })
  */

  // TODO test overridePackageManager != null

  afterEach(() => {
    mockFs.restore()
  })
  //afterAll(() => {
  //  mockFs.restore()
  //})
})

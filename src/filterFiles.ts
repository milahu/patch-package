import { join } from "./path"
import { removeSync } from "fs-extra"
import klawSync from "klaw-sync"

const isDebug = global.patchPackageIsDebug

export function removeIgnoredFiles(
  dir: string,
  includePaths: RegExp,
  excludePaths: RegExp,
) {
  if (isDebug) {
    console.log(`patch-package: removeIgnoredFiles: dir = ${dir}`)
    console.log(`patch-package: removeIgnoredFiles: includePaths = ${includePaths}`)
    console.log(`patch-package: removeIgnoredFiles: excludePaths = ${excludePaths}`)
  }
  klawSync(dir, { nodir: true })
    .map((item) => item.path.slice(`${dir}/`.length))
    .filter(
      (relativePath) =>
        !relativePath.match(includePaths) || relativePath.match(excludePaths),
    )
    .forEach((relativePath) => {
      if (isDebug) {
        console.log(`removeIgnoredFiles: remove ${relativePath}`)
      }
      removeSync(join(dir, relativePath))
    })
}

import { generateTestCase } from "./testCases"
import { executeTestCase } from "./executeTestCase"

describe("property based tests", () => {
  //for (let i = 0; i < 200; i++) {
  // run less tests to save time
  //for (let i = 0; i < 50; i++) {
  for (let i = 0; i < 20; i++) {
    describe(`${i}`, () => {
      executeTestCase(generateTestCase())
    })
  }
})

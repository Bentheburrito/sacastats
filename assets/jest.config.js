/**
 * @type {import('@jest/globals')}
 */
export default {
    "roots": [
        "<rootDir>/test"
    ],
    "testMatch": ['**/test/**/*.test.ts'],
    "transform": {
        "^.+\\.(ts|tsx)$": "ts-jest"
    }
};
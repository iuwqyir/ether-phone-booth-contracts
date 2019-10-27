module.exports = {
    root: true,
    env: {
        node: true
    },
    parserOptions: {
        ecmaVersion: 2017,
    },
    extends: "eslint:recommended",
    rules: {
        "indent": [
            "error",
            4
        ],
        "linebreak-style": [
            "error",
            "unix"
        ],
        "quotes": [
            "error",
            "double"
        ],
        "semi": [
            "error",
            "always"
        ]
    }
};

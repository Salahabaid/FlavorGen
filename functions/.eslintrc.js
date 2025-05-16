module.exports = {
  root: true,
  env: {
    es6: true,
    node: true,
  },
  extends: [
    'eslint:recommended',
    'google',
  ],
  parserOptions: {
    ecmaVersion: 2020,
  },
  rules: {
    'max-len': 'off', // Désactive la règle max-len
  },
};

## Venzra API

Venzra commerce solution - API

[![CircleCI](https://circleci.com/gh/sysen-limited/venzra-api.svg?style=svg&circle-token=51b652522428b98fa9f056b136214bcf60f481e2)](https://circleci.com/gh/sysen-limited/venzra-api)

### Overview

This is the API which will back all Venzra products and is designed as a highly available / scalable solution.

### Requirements

- Node 8
- Mongo DB 3.6 (or newer)

### Available commands

- npm install  
  Installs required dependencies, must always be run before any other commands will work

- npm run test:local  
  This uses express directly to execute the functional tests
  
- npm start  
  Runs serverless offline locally to allow for development of UI
  
- npm deploy:test  
  Performs a deployment to the test environment
  
### Deployment

This is performed via Circle CI and uses the scripts `npm run test:ci` and `npm run deploy:prod` to perform required checks and deployments

#### Image CDN (managed by the API)

The image CDN is managed by the API for deployments to different environments the following variables should be set for the environment.

| variable | example | description |
| :--- | :--- | :--- |
| DEPLOY_CERT | arn:aws:acm:us-east-1:xxxxxxxxxxxx | AWS certificate ARN, certificate must exist on US-EAST-1 |
| DEPLOY_URI | images.venzra.com | The domain for which to create this CDN |
| DEPLOY_STACK | image-cdn-venzra | The name for AWS to use to reference this environment |

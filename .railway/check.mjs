import assert from "node:assert/strict";

import defineProject from "./railway.ts";

const desired = await defineProject({ environment: "production" });
const resources = new Map(
  desired.resources.map((resource) => [resource.name, resource]),
);
const database = resources.get("Postgres");
const api = resources.get("api");
const web = resources.get("web");

assert.equal(desired.name, "berufe-production");
assert.equal(database?.type, "database");
assert.equal(api?.build?.dockerfilePath, "apps/api/Dockerfile");
assert.deepEqual(api?.deploy?.preDeployCommand, [
  "bin/rails db:prepare db:seed",
]);
assert.equal(
  api?.deploy?.multiRegionConfig?.["us-east4-eqdc4a"]?.numReplicas,
  1,
);
assert.equal(api?.variables?.DATABASE_URL?.resource, "database.Postgres");
assert.equal(api?.variables?.SECRET_KEY_BASE?.type, "preserve");
assert.equal(web?.source?.rootDirectory, "apps/web");
assert.equal(
  web?.deploy?.multiRegionConfig?.["us-east4-eqdc4a"]?.numReplicas,
  1,
);
assert.equal(
  web?.variables?.NUXT_API_INTERNAL_BASE_URL?.value,
  "http://${{api.RAILWAY_PRIVATE_DOMAIN}}",
);
assert.equal(web?.variables?.NUXT_PUBLIC_BUGSNAG_API_KEY?.type, "preserve");

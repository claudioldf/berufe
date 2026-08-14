import assert from "node:assert/strict";
import { mkdtemp, readFile, rm } from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import test from "node:test";

import {
  professionalsToCsv,
  validateOutputFormat,
  writeFormattedOutput,
} from "../src/output.js";

const result = {
  city: "sao-paulo",
  count: 1,
  professionals: [
    {
      name: "Empresa, Serviços",
      category: "Eletricista",
      position: 2,
      city: "São Paulo",
      state: "SP",
      whatsapp: "5511900000000",
      listingCategories: [
        { name: "Eletricista", slug: "eletricista", position: 2 },
        { name: "Encanador", slug: "encanador", position: 4 },
      ],
    },
  ],
  errors: [],
};

test("serializes professional records as RFC-compatible CSV", () => {
  assert.equal(
    professionalsToCsv(result.professionals),
    [
      "name,category,position,city,state,whatsapp,listing_categories",
      '\"Empresa, Serviços\",Eletricista,2,São Paulo,SP,5511900000000,eletricista:2|encanador:4',
      "",
    ].join("\n"),
  );
});

test("returns JSON for CLI output", async () => {
  const output = await writeFormattedOutput({
    city: "sao-paulo",
    format: "cli",
    result,
  });

  assert.equal(output.filePath, null);
  assert.deepEqual(JSON.parse(output.contents), result);
});

test("uses the results directory for generated files by default", async () => {
  const outputDirectory = await mkdtemp(path.join(os.tmpdir(), "leads-cwd-"));
  const previousDirectory = process.cwd();
  process.chdir(outputDirectory);

  try {
    const output = await writeFormattedOutput({
      city: "sao-paulo",
      format: "json",
      result,
    });

    assert.equal(
      path.relative(process.cwd(), output.filePath),
      path.join("results", "sao-paulo.json"),
    );
    assert.ok((await readFile(output.filePath, "utf8")).length > 0);
  } finally {
    process.chdir(previousDirectory);
    await rm(outputDirectory, { force: true, recursive: true });
  }
});

test("writes JSON and CSV files", async (context) => {
  const outputDirectory = await mkdtemp(path.join(os.tmpdir(), "leads-output-"));
  context.after(() => rm(outputDirectory, { force: true, recursive: true }));

  for (const format of ["json", "csv"]) {
    const output = await writeFormattedOutput({
      city: "sao-paulo",
      format,
      outputDirectory,
      result,
    });

    assert.equal(output.filePath, path.join(outputDirectory, `sao-paulo.${format}`));
    assert.ok((await readFile(output.filePath, "utf8")).length > 0);
  }
});

test("rejects unknown output formats", () => {
  assert.throws(() => validateOutputFormat("xml"), /output format must be one of/);
});

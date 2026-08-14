import { mkdir, writeFile } from "node:fs/promises";
import path from "node:path";

import { ValidationError } from "./errors.js";

export const OUTPUT_FORMATS = new Set(["json", "csv", "cli"]);

function csvCell(value) {
  const text = String(value ?? "");
  return /[",\r\n]/.test(text) ? `"${text.replaceAll('"', '""')}"` : text;
}

export function professionalsToCsv(professionals) {
  const rows = [
    [
      "name",
      "category",
      "position",
      "city",
      "state",
      "whatsapp",
      "listing_categories",
    ],
    ...professionals.map((professional) => [
      professional.name,
      professional.category,
      professional.position,
      professional.city,
      professional.state,
      professional.whatsapp,
      (professional.listingCategories ?? [])
        .map((category) => `${category.slug}:${category.position}`)
        .join("|"),
    ]),
  ];

  return `${rows.map((row) => row.map(csvCell).join(",")).join("\n")}\n`;
}

export function validateOutputFormat(format) {
  if (!OUTPUT_FORMATS.has(format)) {
    throw new ValidationError(
      `output format must be one of: ${[...OUTPUT_FORMATS].join(", ")}.`,
    );
  }
  return format;
}

export async function writeFormattedOutput({
  city,
  format,
  outputDirectory = path.resolve(process.cwd(), "results"),
  result,
}) {
  validateOutputFormat(format);

  if (format === "cli") {
    return { contents: `${JSON.stringify(result, null, 2)}\n`, filePath: null };
  }

  const contents =
    format === "csv"
      ? professionalsToCsv(result.professionals)
      : `${JSON.stringify(result, null, 2)}\n`;
  await mkdir(outputDirectory, { recursive: true });
  const filePath = path.resolve(outputDirectory, `${city}.${format}`);
  await writeFile(filePath, contents, "utf8");
  return { contents: null, filePath };
}

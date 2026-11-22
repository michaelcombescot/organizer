import type { ErrHandler } from "../backend/api/RegistryIndexes";
import { i18n } from "./i18n";
import type { Translations } from "./language";

function assertNever(value: never, context?: string): never {
  throw new Error(
    context
      ? `Unhandled variant in ${context}: ${JSON.stringify(value)}`
      : `Unhandled variant: ${JSON.stringify(value)}`
  );
}

function fieldLabel(field: string): string {
  const tr = i18n();
  const value = tr[field as Extract<keyof Translations, string>];
  return typeof value === "string" ? value : field;
}

export function displayErrorMessage(err: ErrHandler) {
  switch (err.__kind__) {
    case "errValidation":
      return err.errValidation
        .map((issue) => {
          switch (issue.__kind__) {
            case "alreadyExists": 
              return i18n().errAlreadyExists(fieldLabel(issue.alreadyExists.field));
            case "badLength":
              return i18n().errBadLength(fieldLabel(issue.badLength.field), issue.badLength.min, issue.badLength.max);
            default:
              return assertNever(issue, "errValidation");
          }
        })
    .join("; ");
    case "errInterCanisterCall":
      return `Inter-canister call error: ${err.errInterCanisterCall}`;

    case "errBadRequest":
      return `Bad request: ${err.errBadRequest}`;

    case "errMemoryLimitReached":
      return "Memory limit reached";

    case "errIndexNotFound":
      return "Index not found";

    case "errUpdateOngoing":
      return "Update already ongoing";

    case "errJob":
      // err.errJob is narrowed to ErrJob
      return `Job error: ${JSON.stringify(err.errJob)}`;

    case "errMustBeController":
      return "Caller must be controller";

    case "errMustNotBeAnonymous":
      return "Anonymous caller is not allowed";

    case "errSystem":
      return `System error: ${err.errSystem}`;

    case "errIndexAlreadyExists":
      return "Index already exists";

    case "errWrongCanister":
      return "Wrong canister";

    case "errCanisterFull":
      return "Canister is full";

    case "errGuarded":
      return "Operation is guarded";

    case "errNotFound":
      return `Not found: ${err.errNotFound}`;

    case "errForbidden":
      return "Forbidden";

    case "errCannotVerifyCaller":
      return "Cannot verify caller";

    default:
      return assertNever(err, "handleErr");
  }
}
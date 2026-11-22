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

export function displayErrorMessage(err: ErrHandler | null) : string[] {
  let errors: string[] = [];

  if (!err) {
    return errors;
  }

  switch (err.__kind__) {
    case "errValidation":
      err.errValidation
        .map((issue) => {
          switch (issue.__kind__) {
            case "alreadyExists": 
              errors.push(i18n().errAlreadyExists(fieldLabel(issue.alreadyExists.field)));
              break
            case "badLength":
              errors.push(i18n().errBadLength(fieldLabel(issue.badLength.field), issue.badLength.min, issue.badLength.max));
              break
            default:
              assertNever(issue, "errValidation");
          }
        })
      break
    case "errInterCanisterCall":
      errors.push(`Inter-canister call error: ${err.errInterCanisterCall}`);
      break
    case "errBadRequest":
      errors.push(`Bad request: ${err.errBadRequest}`);
      break

    case "errMemoryLimitReached":
      errors.push("Memory limit reached");
      break

    case "errIndexNotFound":
      errors.push("Index not found");
      break

    case "errUpdateOngoing":
      errors.push("Update already ongoing");
      break

    case "errJob":
      errors.push(`Job error: ${JSON.stringify(err.errJob)}`);
      break

    case "errMustBeController":
      errors.push("Caller must be a controller");
      break

    case "errMustNotBeAnonymous":
      errors.push("Caller must not be anonymous");
      break

    case "errSystem":
      errors.push(`System error: ${err.errSystem}`);
      break

    case "errIndexAlreadyExists":
      errors.push("Index already exists");
      break

    case "errWrongCanister":
      errors.push("Wrong canister");
      break

    case "errCanisterFull":
      errors.push("Canister is full");
      break

    case "errGuarded":
      errors.push("Operation is guarded");
      break

    case "errNotFound":
      errors.push(`Not found: ${err.errNotFound}`);
      break

    case "errForbidden":
      errors.push("Forbidden");
      break

    case "errCannotVerifyCaller":
      errors.push("Cannot verify caller");
      break

    default:
      assertNever(err, "handleErr");
  }

  return errors;
}
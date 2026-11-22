import type { TargetedSubmitEvent } from "preact";

export async function submitFormWrapper(e: TargetedSubmitEvent<HTMLFormElement>, submitForm: () => Promise<void>) {
  e.preventDefault();

  const submitButton = e.currentTarget.querySelector<HTMLButtonElement>("button[type=submit]")!;
  submitButton.disabled = true;

  await submitForm();

  submitButton.disabled = false;
};
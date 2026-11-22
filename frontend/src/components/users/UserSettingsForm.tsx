import { useDeepSignal } from "deepsignal";
import { i18n } from "../../i18n/i18n";
import { actorBucketUsersCurrent } from "../../backend/actors/bucketUsers";
import { useSignal } from "@preact/signals";
import { stateModal } from "../../states/display";
import { stateUserData } from "../../states/user";
import type { ErrHandler } from "../../backend/api/BucketUsers";
import { displayErrorMessage } from "../../i18n/helpers";

export default function UserSettingsForm() {
  const formData = useDeepSignal({
    name: stateUserData.userData.name,
    email: stateUserData.userData.email
  });

  const formErrors = useSignal<ErrHandler | null>(null);

  let submitForm = async (e: Event) => {
    e.preventDefault();
    let resp = await (await actorBucketUsersCurrent()).handlerUpdateUser({
      name: formData.name,
      email: formData.email
    });

    if (resp && "ok" in resp) {
      stateModal.value = { visible: false, content: null };
      stateUserData.userData.email = formData.email;
      stateUserData.userData.name = formData.name;
    } else if (resp && "err" in resp) {
      formErrors.value = resp.err;

      debugger
    }
  };

  return (
    <form onSubmit={submitForm}>
      <h2>{i18n().userSettingsFormTitle}</h2>

      <div class="error-message">
        {formErrors.value && displayErrorMessage(formErrors.value)}
      </div>

      <div class="form-group">
        <label for="name">{i18n().userSettingsFormNameLabel}</label>
        <input
          id="name"
          value={formData.name}
          onInput={(e) => formData.name = e.currentTarget.value }
          type="text"
          placeholder={i18n().userSettingsFormNameLabel}
          // minLength={3}
          // maxLength={100}
        />
      </div>

      <div class="form-group">
        <label for="email">{i18n().userSettingsFormEmailLabel}</label>
        <input
          id="email"
          value={formData.email}
          onInput={(e) => formData.email = e.currentTarget.value }
          type="email"
          placeholder={i18n().userSettingsFormEmailLabel}
          minLength={3}
          maxLength={100}
        />
      </div>

      <button type="submit">{i18n().userSettingsFormSaveButton}</button>
    </form>
  );
}
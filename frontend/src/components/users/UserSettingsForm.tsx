import { useDeepSignal } from "deepsignal";
import i18n from "../../i18n/i18n";
import { actorBucketUsers } from "../../backend/actors/bucketUsers";
import { useSignal } from "@preact/signals";
import type { HandlerErr } from "../../backend/api/BucketUsers";
import { stateModal } from "../../states/display";
import { stateUserData } from "../../states/user";

export default function UserSettingsForm() {
  const formData = useDeepSignal({
    name: stateUserData.userData.name,
    email: stateUserData.userData.email
  });

  const formErrors = useSignal<HandlerErr[]>([]);

  let submitForm = async (e: Event) => {
    e.preventDefault();
    let resp = await (await actorBucketUsers()).handlerUpdateUser({
      name: formData.name,
      email: formData.email
    });

    if (resp && "ok" in resp) {
      stateModal.value = { visible: false, content: null };
      stateUserData.userData.email = formData.email;
      stateUserData.userData.name = formData.name;
    } else if (resp && "err" in resp) {
      formErrors.value.push(resp.err);
    }
  };

  return (
    <form onSubmit={submitForm}>
      <h2>{i18n().userSettingsFormTitle}</h2>

    

      <div class="form-group">
        <label for="name">{i18n().userSettingsFormNameLabel}</label>
        <input
          id="name"
          value={formData.name}
          onInput={(e) => formData.name = e.currentTarget.value }
          type="text"
          placeholder={i18n().userSettingsFormNameLabel}
          minLength={1}
          maxLength={100}
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
          minLength={1}
          maxLength={100}
        />
      </div>

      <button type="submit">{i18n().userSettingsFormSaveButton}</button>
    </form>
  );
}
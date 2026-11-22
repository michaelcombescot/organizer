import { useDeepSignal } from "deepsignal";
import { i18n } from "../../i18n/i18n";
import { useSignal } from "@preact/signals";
import type { ErrHandler } from "../../backend/api/BucketUsers";
import { SearchIndexesActor } from "../../backend/actors/searchIndexes";

export default function UserSearchForm() {
  const formData = useDeepSignal({
    key: "",
  });

  const formErrors = useSignal<ErrHandler[]>([]);

  let submitForm = async (e: Event) => {
    e.preventDefault();
    // let resp = await (await actorBucketUsersCurrent()).handlerUpdateUser({
    //   name: formData.name,
    //   email: formData.email
    // });

    // if (resp && "ok" in resp) {
    //   stateModal.value = { visible: false, content: null };
    //   stateUserData.userData.email = formData.email;
    //   stateUserData.userData.name = formData.name;
    // } else if (resp && "err" in resp) {
    //   formErrors.value.push(resp.err);
    // }
  };

  return (
    <form onSubmit={submitForm}>
      <h2>{i18n().userSearchFormTitle}</h2>

      <div class="form-group">
        <label for="name">{i18n().userFormSearchKey}</label>
        <input
          id="name"
          value={formData.key}
          onInput={async (e) => { 
            let resp = await new SearchIndexesActor().searchUsersFromText(e.currentTarget.value)

            debugger
          }}
          type="text"
          placeholder={i18n().userSettingsFormNameLabel}
          minLength={1}
          maxLength={100}
        />
      </div>

      <div>
      </div>

      <button type="submit">{i18n().userSettingsFormSaveButton}</button>
    </form>
  );
}
import { i18n } from "../../i18n/i18n";
import { Signal, useSignal } from "@preact/signals";
import type { PublicUser } from "../../backend/api/BucketUsers";
import { SearchIndexesActor } from "../../backend/actors/searchIndexes";

export default function UserSearchForm() {
  console.log("UserSearchForm rendered");

  const users = useSignal<PublicUser[]>([]);

  let submitForm = async (e: Event) => {
    e.preventDefault();
  };

  return (
    <form onSubmit={submitForm}>
      <h2>{i18n().userSearchFormTitle}</h2>

      <div class="form-group">
        <label for="name">{i18n().userFormSearchKey}</label>
        <input
          id="name"
          onInput={async (e) => { 
            const resp = await new SearchIndexesActor().searchUsersFromText(e.currentTarget.value);
            users.value = resp;
          }}
          type="text"
          placeholder={i18n().userSettingsFormNameLabel}
          minLength={1}
          maxLength={100}
        />
      </div>

      <UserResults users={users} />

      <button type="submit">{i18n().userSettingsFormSaveButton}</button>
    </form>
  );
}

function UserResults({ users }: { users: Signal<PublicUser[]> }) {
  return (
    <ul>
      {users.value?.map((user) => (
        <li key={user.principal.toText()} id={user.principal.toText()}>
          <p>{user.name} ({user.email})</p>
        </li>
      ))}
    </ul>
  );
}
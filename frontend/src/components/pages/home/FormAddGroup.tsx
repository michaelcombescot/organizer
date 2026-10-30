import { useState } from "preact/hooks";
import { actorBackend } from "../../../backend/actors/backend";
import { Kind, type CreateGroupParams } from "../../../backend/api/backend";
import i18n from "../../../i18n/i18n";
import { changeStateDisplayFlash, useModalStore } from "../../../states/display";
import { changeStateGroups } from "../../../states/home";

export default function FormAddGroup() {
  const [group, setGroup] = useState<CreateGroupParams>({
    name: "",
    kind: Kind.personnal,
    color: "#3498db",
  });
  const modalStore = useModalStore();

  async function submit(event: Event) {
    event.preventDefault();

    try {
      const response = await (await actorBackend()).createGroup(group);
      if (response.err) {
        changeStateDisplayFlash("error", response.err);
        return;
      }
      if (response.ok) {
        changeStateGroups("add", response.ok);
        modalStore.closeModal();
      }
    } catch (error) {
      changeStateDisplayFlash("error", error);
    }
  }

  return (
    <section>
      <h1>{i18n().groupFormNewTitle}</h1>
      <form onSubmit={submit}>
        <div class="form-group">
          <label class="required" for="name">{i18n().groupFormNameLabel}</label>
          <input
            id="name"
            value={group.name}
            onInput={(event) =>
              setGroup({ ...group, name: event.currentTarget.value })
            }
            type="text"
            placeholder="Group name"
            required
            minLength={1}
            maxLength={100}
          />
        </div>
        <div class="form-group">
          <label class="required" for="kind">{i18n().groupFormKindLabel}</label>
          <select
            id="kind"
            value={group.kind}
            onChange={(event) =>
              setGroup({ ...group, kind: event.currentTarget.value as Kind })
            }
            required
          >
            {Object.values(Kind).map((kind) => (
              <option key={kind} value={kind}>{i18n().groupKind[kind]}</option>
            ))}
          </select>
        </div>
        <div class="form-group">
          <label class="required" for="color">{i18n().groupFormColorLabel}</label>
          <input
            id="color"
            value={group.color}
            onInput={(event) =>
              setGroup({ ...group, color: event.currentTarget.value })
            }
            type="color"
            required
          />
        </div>
        <button type="submit">{i18n().formSubmit}</button>
      </form>
    </section>
  );
}

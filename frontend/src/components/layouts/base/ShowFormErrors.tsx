import type { ErrHandler } from "../../../backend/api/RegistryIndexes";
import { displayErrorMessage } from "../../../i18n/helpers";

export default function ShowFormErrors({ errors }: { errors: ErrHandler | null }) {
  return (
    <div class="error-message">
      <ul>
        {errors && displayErrorMessage(errors).map((err, index) => (
          <li key={index}>{err}</li>
        ))}
      </ul>
    </div>
  );
}

import { stateFlashes } from "../../../states/display";

export default function Flashes() {
  return (
    <>
      <div class="flashes" role="alert">
        {stateFlashes.flashInfo.length != 0 && (
          <div class="flash" id="flash-info">
            {stateFlashes.flashInfo}
          </div>
        )}
        {stateFlashes.flashError.length != 0 && (
          <div class="flash" id="flash-error">
            {stateFlashes.flashError}
          </div>
        )}
        {stateFlashes.flashWarning.length != 0 && (
          <div class="flash" id="flash-warning">
            {stateFlashes.flashWarning}
          </div>
        )}
      </div>
    </>
  );
}
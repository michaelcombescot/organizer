import { stateFlash } from "../../../states/display";

export default function Flashes() {
  return (
    <>
      <div class="flashes" role="alert">
        {stateFlash.flashInfo.length != 0 && (
          <div class="flash" id="flash-info">
            {stateFlash.flashInfo}
          </div>
        )}
        {stateFlash.flashError.length != 0 && (
          <div class="flash" id="flash-error">
            {stateFlash.flashError}
          </div>
        )}
        {stateFlash.flashWarning.length != 0 && (
          <div class="flash" id="flash-warning">
            {stateFlash.flashWarning}
          </div>
        )}
      </div>
    </>
  );
}
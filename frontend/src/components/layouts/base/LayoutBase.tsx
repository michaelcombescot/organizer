import Router, { Route } from "preact-router";
import { authenticated, STATE_PRINCIPAL, signIn, signOut } from "../../../stores/auth";
import i18n from "../../../i18n/i18n";
import Home from "../../pages/home/Home";
import Sidebar from "./Sidebar";
import Modal from "./Modal";
import { displayFlash } from "../../../stores/display";

export default function LayoutBase() {
  return (
    <div class="layout-base">
      <header class="flex justify-between items-center">
        <div id="actions-login-logout">
          {authenticated.value ? (
            <button
              id="action-logout"
              title={STATE_PRINCIPAL}
              type="button"
              onClick={() => void signOut()}
            >
              {i18n().layoutLogoutLink}
            </button>
          ) : (
            <button id="action-login" type="button" onClick={() => void signIn()}>
              {i18n().layoutLoginLink}
            </button>
          )}
        </div>
      </header>

      <Sidebar />
      <Modal />
      {displayFlash.value && (
        <div class="flashes" role="alert">
          <div class="flash" id={`flash-${displayFlash.value.type}`}>
            {displayFlash.value.message}
          </div>
        </div>
      )}

      <main>
        <Router>
          <Route path="/" component={Home} />
        </Router>
      </main>
    </div>
  );
}

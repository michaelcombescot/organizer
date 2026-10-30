import Router, { Route } from "preact-router";
import { stateAuthenticated, statePrincipal, signIn, signOut } from "../../../states/auth";
import i18n from "../../../i18n/i18n";
import Home from "../../pages/home/Home";
import Sidebar from "./Sidebar";
import Modal from "./Modal";
import Flashes from "./Flashes";

export default function LayoutBase() {
  return (
    <div class="layout-base">
      <header class="flex justify-between items-center">
        <div id="actions-login-logout">
          {stateAuthenticated.value ? (
            <button
              id="action-logout"
              title={statePrincipal.value}
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
      <Flashes />

      <main>
        <Router>
          <Route path="/" component={Home} />
        </Router>
      </main>
    </div>
  );
}

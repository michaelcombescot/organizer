import Router, { Route } from "preact-router";
import { stateAuthenticated, statePrincipal, signIn, signOut } from "../../../states/auth";
import i18n from "../../../i18n/i18n";
import Home from "../../pages/home/Home";
import Sidebar from "./Sidebar";
import Modal from "./Modal";
import Flashes from "./Flashes";
import { stateModal } from "../../../states/display";
import UserSettingsForm from "../../users/UserSettingsForm";

export default function LayoutBase() {
  return (
    <div class="layout-base">
      <header class="flex justify-between items-center">
        <div id="actions-login-logout">
          {stateAuthenticated.value ? (
            <button 
              popovertarget="popover-user-menu" 
              class="cursor-pointer border-none bg-transparent p-0 [anchor-name:--user-menu]"
            >
              <img 
                src="/profil.svg" 
                alt="Profile" 
                class="size-8" 
              />

              <div 
                id="popover-user-menu" 
                popover 
                class="m-0 absolute w-100 [position-anchor:--user-menu] [position-area:bottom_span-left] bg-white shadow-lg rounded-md p-2"
              >
                <ul>
                  <li class="font-mono text-sm flex items-center gap-1 overflow-hidden">
                    <span class="shrink-0">{i18n().layoutUserPrincipal}:</span>
                    <span title={statePrincipal.value} class="truncate min-w-0 flex-1">
                      {statePrincipal.value}
                    </span>
                  </li>
                  <li
                    class="cursor-pointer hover:bg-gray-100 p-1 rounded"
                    onClick={() => stateModal.value = { visible: true, content: <UserSettingsForm /> } }
                  >
                    {i18n().layoutUserSettingsLink}
                  </li>
                  <li
                    onClick={() => void signOut()} 
                    class="cursor-pointer hover:bg-gray-100 p-1 rounded"
                  >
                    {i18n().layoutLogoutLink}
                  </li>
                </ul>
              </div>
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

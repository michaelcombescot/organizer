import { stateModal } from "../../../states/display";
import UserSearchForm from "../../users/UserSearchForm";

export default function Home() {
  return (
    <section class="home">
      <button id="home-new-todo" type="button">New Todo</button>
      <div id="home-todo-lists-wrapper">
        <div class="home-todo-lists" />
        <div class="home-todo-lists" />
      </div>

      <div class="cursor-pointer hover:bg-gray-100 p-1 rounded"
                          onClick={() => stateModal.value = { visible: true, content: <UserSearchForm /> } }>SEARCH</div>
    </section>
  );
}

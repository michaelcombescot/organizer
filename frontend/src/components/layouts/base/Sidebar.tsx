import { stateSidebar } from "../../../states/display";

export default function Sidebar() {
  if (!stateSidebar.value) return <></>

  return (
    <>
      <div class="fixed inset-0 z-40 w-64 bg-white border-r">
        <button
          class="absolute top-1 right-1 h-8 w-8 rounded-full text-gray-400 hover:bg-gray-100 hover:text-gray-700"
          type="button"
          aria-label="Close sidebar"
          onClick={() => stateSidebar.value = false}
        >
          ✕
        </button>
        <div class="pt-10">
          <h1 class="font-bold">Dashboards</h1>
          <ul class="pt-2">
            <li class="flex"><a href="#">Dashboard 1</a></li>
          </ul>
        </div>
      </div>
    </>   
  );
}

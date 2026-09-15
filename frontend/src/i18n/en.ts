import { Kind, Priority, Status } from "../backend/api/backend";
import type { Language } from "./language";

export const ENGLISH: Language = {
  code: "en",
  name: "English",
  translations: {
    // ===== LAYOUT =====
    connectingMessage: "Connecting to canister...",

    layoutLoginLink: "Login",
    layoutLogoutLink: "Logout",
    
    // ===== HOME =====
    homeSidebarTitleGroups: "Groups",
    homeSidebarSelectGroupsAll: "All groups",

    // ===== GROUPS =====
    groupDeleteConfirm: (name: string) => 
      `Are you sure you want to delete '${name}'? \nThis action cannot be undone`,

    groupFormNewTitle: "New group",
    groupFormEditTitle: "Edit Group",
    groupFormNameLabel: "Name",
    groupFormKindLabel: "Kind",
    groupFormColorLabel: "Color",

    groupAddUserFormTitle: (name: string) => 
      `Add user to '${name}'`,
    groupAddUserFormSearchBy: "Search by",
    groupAddUserFormSearchValue: "Search value",

    groupKind: {
        [Kind.collective]: "Collective",
        [Kind.personnal]: "Personal",
    },

    // ===== TODOS =====
    todoFormNewTitle: "New todo",
    todoFormEditTitle: "Edit Todo",
    todoFormGroupLabel: "Group",
    todoFormGroupNoneSelected: "No group",
    todoFormTitleLabel: "Title",
    todoFormDescriptionLabel: "Description",
    todoFormScheduledDateLabel: "Scheduled date",
    todoFormPriorityLabel: "Priority",
    todoFormStatusLabel: "Status",

    todoPriority: {
        [Priority.low]: "Low",
        [Priority.medium]: "Medium",
        [Priority.high]: "High",
      },
    todoStatus: {
        [Status.todo]: "To Do",
        [Status.inProgress]: "In Progress",
        [Status.done]: "Done",
      },

    // ===== FORM =====
    formSubmit: "Submit",

    // ===== HOME =====
    todoCardConfirmDone: "Are you sure you want to mark this todo as done? The todo will be deleted.",
  }
};
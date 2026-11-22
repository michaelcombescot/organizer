import type { Language } from "./language";

export const ENGLISH: Language = {
  code: "en",
  name: "English",
  translations: {
    // ===== LAYOUT =====
    connectingMessage: "Connecting to canister...",

    layoutLoginLink: "Login",
    layoutLogoutLink: "Logout",
    layoutUserPrincipal: "Your principal",  
    layoutUserSettingsLink: "Settings",
    
    // ===== USERS =====

    userSettingsFormTitle: "User Settings",
    userSettingsFormNameLabel: "Name",
    userSettingsFormEmailLabel: "Email",
    userSettingsFormSaveButton: "Save",

    userSearchFormTitle: "User Search",
    userFormSearchKey: "Search Key",

    // ===== HOME =====
    homeSidebarTitleGroups: "Groups",
    homeSidebarSelectGroupsAll: "All groups",

    // ===== ERRORS =====

    errAlreadyExists: (field: string) => `${field} already exists`,
    errBadLength: (field: string, min: bigint, max: bigint) => `${field} must be between ${min} and ${max} characters`,

    // ===== FIELDS =====

    name: "Name",
    email: "Email",

    // // ===== GROUPS =====
    // groupDeleteConfirm: (name: string) => 
    //   `Are you sure you want to delete '${name}'? \nThis action cannot be undone`,

    // groupFormNewTitle: "New group",
    // groupFormEditTitle: "Edit Group",
    // groupFormNameLabel: "Name",
    // groupFormKindLabel: "Kind",
    // groupFormColorLabel: "Color",

    // groupAddUserFormTitle: (name: string) => 
    //   `Add user to '${name}'`,
    // groupAddUserFormSearchBy: "Search by",
    // groupAddUserFormSearchValue: "Search value",

    // groupKind: {
    //     [Kind.collective]: "Collective",
    //     [Kind.personnal]: "Personal",
    // },

    // // ===== TODOS =====
    // todoFormNewTitle: "New todo",
    // todoFormEditTitle: "Edit Todo",
    // todoFormGroupLabel: "Group",
    // todoFormGroupNoneSelected: "No group",
    // todoFormTitleLabel: "Title",
    // todoFormDescriptionLabel: "Description",
    // todoFormScheduledDateLabel: "Scheduled date",
    // todoFormPriorityLabel: "Priority",
    // todoFormStatusLabel: "Status",

    // todoPriority: {
    //     [Priority.low]: "Low",
    //     [Priority.medium]: "Medium",
    //     [Priority.high]: "High",
    //   },
    // todoStatus: {
    //     [Status.todo]: "To Do",
    //     [Status.inProgress]: "In Progress",
    //     [Status.done]: "Done",
    //   },
  }
};
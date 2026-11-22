export interface Language {
    code: string;
    name: string;
    translations: Translations;
}

export interface Translations {
    // ===== LOADING_APP =====
    connectingMessage: string;

    // ===== LAYOUT =====
    layoutLoginLink: string;
    layoutLogoutLink: string;
    layoutUserPrincipal: string;
    layoutUserSettingsLink: string;

    // ===== USERS =====

    userSettingsFormTitle: string;
    userSettingsFormNameLabel: string;
    userSettingsFormEmailLabel: string;
    userSettingsFormSaveButton: string;

    userSearchFormTitle: string;
    userFormSearchKey: string;

    // ===== HOME =====
    homeSidebarTitleGroups: string,
    homeSidebarSelectGroupsAll: string,

    // ===== ERRORS =====
    errAlreadyExists: (field: string) => string;
    errBadLength: (field: string, min: bigint, max: bigint) => string;

    // ===== FIELDS =====
    name: string;
    email: string;

    // // ===== GROUP =====
    // groupDeleteConfirm: (groupName: string) => string;

    // groupFormNewTitle: string;
    // groupFormEditTitle: string;
    // groupFormNameLabel: string;
    // groupFormKindLabel: string;
    // groupFormColorLabel: string;

    // groupKind: Record<Kind, string>;

    // groupAddUserFormTitle: (groupName: string) => string;
    // groupAddUserFormSearchBy: string;
    // groupAddUserFormSearchValue: string;

    // // ===== TODO =====
    // todoFormNewTitle: string;
    // todoFormEditTitle: string;
    // todoFormGroupLabel: string;
    // todoFormGroupNoneSelected: string;
    // todoFormTitleLabel: string;
    // todoFormDescriptionLabel: string;
    // todoFormScheduledDateLabel: string;
    // todoFormPriorityLabel: string;
    // todoFormStatusLabel: string;

    // todoPriority: Record<Priority, string>;
    // todoStatus: Record<Status, string>;
}
const POSTFIX = '.sacastats.flex.bootstrap.table';

//Main Events
export const initializedEvent = 'initialized' + POSTFIX;
export const formatsUpdatedEvent = 'formats-updated' + POSTFIX;
export const ADD_DESKTOP_HEADER_ONLY_EVENT = 'add-desktop-header-only' + POSTFIX;

//Filter Events
export const filteredEvent = 'filtered' + POSTFIX;
export const ADD_CUSTOM_FILTER_FUNCTIONS_EVENT = 'add-custom-filter-functions' + POSTFIX;
export const ADD_CUSTOM_SEARCH_FUNCTION_EVENT = 'add-custom-search-function' + POSTFIX;

//Column Events
export const COLUMN_SORT_CHANGED_EVENT = 'column-sort-changed' + POSTFIX;
export const COLUMNS_CHANGED_EVENT = 'columns-changed' + POSTFIX;

//Selection Events
export const ADD_CUSTOM_COPY_EVENT = 'add-custom-copy' + POSTFIX;
export const ADD_SECOND_CUSTOM_COPY_EVENT = 'add-second-custom-copy' + POSTFIX;

export function createEvent(eventName: string, ...content: any): CustomEvent<any[]> {
    return new CustomEvent(eventName, { detail: content });
}

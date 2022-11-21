

/* Column Objects */
export interface IPersistentColumn {
    fields: ITableField[];
    sorted: ITableSortedField;
}
export interface IIndexedColumn {
    index: number;
    field: string;
}
export class IndexedColumn implements IIndexedColumn {
    index: number;
    field: string;

    constructor(index: number, field: string) {
        this.index = index;
        this.field = field;
    }
}
export interface IColumnOrderObject {
    [key: string]: number;
}

/* Column Sort Order Objects */
export enum SortOrder {
    NONE = '',
    ASCENDING = 'asc',
    DESCENDING = 'desc',
}
export enum SortOrderIcon {
    NONE = 'fa-sort',
    ASCENDING = 'fa-sort-up',
    DESCENDING = 'fa-sort-down',
}

/* Table Field Objects */
export interface ITableField {
    field: string;
    title: string;
}
export interface ITableSortedField {
    fieldText: string;
    order: SortOrder;
}

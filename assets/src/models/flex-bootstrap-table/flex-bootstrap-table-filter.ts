import { ITableData } from './flex-bootstrap-table.js';

export interface ITableFilter {
  filterID: string;
  [key: string]: string | boolean;
  filterName: string;
  checked: boolean;
}
export class TableFilter implements ITableFilter {
  [key: string]: string | boolean;
  filterID: string;
  filterName: string;
  checked: boolean;

  constructor(filterID: string, filterName: string, checked: boolean) {
    this.filterID = filterID;
    this[filterName] = checked;
    this.filterName = filterName;
    this.checked = checked;
  }
}
export class FilterMap extends Map<string, Array<TableFilter>> {
  constructor() {
    super();
  }
}

/* Custom Filter Function Objects */
export interface ICustomFilterFunction {
  category: string;
  filterFunction: Function;
}
export class CustomFilterFunction implements ICustomFilterFunction {
  category: string;
  filterFunction: Function;

  constructor(category: string, filterFunction: Function) {
    this.category = category;
    this.filterFunction = filterFunction;
  }

  public getCategory(): string {
    return this.category;
  }

  public getFilterFunction() {
    return this.filterFunction;
  }

  public runFilterFunction(filterName: string, dataArray: ITableData[]): ITableData[] {
    return this.filterFunction(filterName, dataArray);
  }
}

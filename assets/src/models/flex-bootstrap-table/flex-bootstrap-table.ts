import { FlexBootstrapTable } from "../../flex_bootstrap_table/flex-bootstrap-table";

export interface ITableData {
    [key: string]: string | Object;
}

export class FlexBootstrapTableMap extends Map<string, FlexBootstrapTable> {
    constructor() {
        super();
    }
}

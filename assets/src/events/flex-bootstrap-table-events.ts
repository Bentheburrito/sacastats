import { SacaStatsEvent } from '../events/sacastats-event.js';

class FlexBootstrapTableEvent<T> extends SacaStatsEvent<T> {
  constructor(eventName: string, ...content: any) {
    super(eventName, ".sacastats.flex.bootstrap.table", ...content);
  }
}

//Main Events
export class InitializedEvent<T> extends FlexBootstrapTableEvent<T> {
  public constructor(...content: any) {
    super("initialized", ...content);
  }
}
export class FormatsUpdatedEvent<T> extends FlexBootstrapTableEvent<T> {
  public constructor(...content: any) {
    super("formats-updated", ...content);
  }
}
export class AddDesktopHeaderOnlyEvent<T> extends FlexBootstrapTableEvent<T> {
  public constructor(...content: any) {
    super("add-desktop-header-only", ...content);
  }
}

//Filter Events
export class FilteredEvent<T> extends FlexBootstrapTableEvent<T> {
  public constructor(...content: any) {
    super("filtered", ...content);
  }
}
export class AddCustomFilterFunctionsEvent<T> extends FlexBootstrapTableEvent<T> {
  public constructor(...content: any) {
    super("add-custom-filter-functions", ...content);
  }
}
export class AddCustomSearchFunctionEvent<T> extends FlexBootstrapTableEvent<T> {
  public constructor(...content: any) {
    super("add-custom-search-function", ...content);
  }
}

//Column Events
export class ColumnSortChangedEvent<T> extends FlexBootstrapTableEvent<T> {
  public constructor(...content: any) {
    super("column-sort-changed", ...content);
  }
}
export class ColumnsChangedEvent<T> extends FlexBootstrapTableEvent<T> {
  public constructor(...content: any) {
    super("columns-changed", ...content);
  }
}

//Selection Events
export class AddCustomCopyEvent<T> extends FlexBootstrapTableEvent<T> {
  public constructor(...content: any) {
    super("add-custom-copy", ...content);
  }
}
export class AddSecondCustomCopyEvent<T> extends FlexBootstrapTableEvent<T> {
  public constructor(...content: any) {
    super("add-second-custom-copy", ...content);
  }
}

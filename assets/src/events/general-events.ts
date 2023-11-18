import { SacaStatsEvent } from '../events/sacastats-event.js';

class GeneralEvent<T> extends SacaStatsEvent<T> {
    constructor(eventName: string, ...content: any) {
        super(eventName, ".sacastats", ...content);
    }
}

export class PageFormattedEvent<T> extends GeneralEvent<T> {
    public constructor(...content: any) {
        super("page-formatted", ...content);
    }
}

export class LoadingScreenRemovedEvent<T> extends GeneralEvent<T> {
    public constructor(...content: any) {
        super("loading-screen-removed", ...content);
    }
}

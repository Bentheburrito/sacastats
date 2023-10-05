export abstract class SacaStatsEvent<T> extends CustomEvent<T> {
    readonly POSTFIX: string;
    readonly NAME: string;

    constructor(eventName: string, eventNamePostFix: string, ...content: any) {
        super((eventName + eventNamePostFix), { detail: content });
        this.NAME = eventName;
        this.POSTFIX = eventNamePostFix;
    }

    public get = (): string => {
        return (this.NAME + this.POSTFIX);
    }
}

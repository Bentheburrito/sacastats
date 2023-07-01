import { SacaStatsEvent } from '../events/sacastats-event.js';

export class SacaStatsEventUtil {

    private static elementEventTypeMap: Map<Element, Array<string>> = new Map<Element, Array<string>>();

    constructor() {
    }

    private static addToElementEventMap = (element: Element, eventType: SacaStatsEvent<any>) => {
        let eventTypeList = new Array<string>();

        if (SacaStatsEventUtil.elementEventTypeMap.has(element)) {
            eventTypeList = SacaStatsEventUtil.elementEventTypeMap.get(element)!;
        }

        eventTypeList.push(eventType.get());
        SacaStatsEventUtil.elementEventTypeMap.set(element, eventTypeList);
    }

    private static removeFromElementEventMap = (element: Element, eventType: SacaStatsEvent<any>) => {
        if (SacaStatsEventUtil.elementEventTypeMap.has(element)) {
            let array = SacaStatsEventUtil.elementEventTypeMap.get(element)!;
            const index = array.indexOf(eventType.get(), 0);
            if (index > -1) {
                array.splice(index, 1);
            }
        }
    }

    private static hasCustomEventListener = (element: Element, eventType: SacaStatsEvent<any>): boolean => {
        if (!SacaStatsEventUtil.elementEventTypeMap.has(element)) {
            return false;
        }

        return SacaStatsEventUtil.elementEventTypeMap.get(element)!.includes(eventType.get());
    }

    public static dispatchDocumentCustomEvent = (customEvent: SacaStatsEvent<any>) => {
        SacaStatsEventUtil.dispatchCustomEvent(document as any, customEvent);
    };

    public static dispatchCustomEvent = async (element: Element, customEvent: SacaStatsEvent<any>) => {
        if (element != null && typeof (element) != 'undefined') {
            SacaStatsEventUtil.waitForListenerThenDispatchEvent(element, customEvent);
            return;
        }

        SacaStatsEventUtil.logDispatchError(element, customEvent, true);
    };

    private static waitForListenerThenDispatchEvent = async (element: Element, customEvent: SacaStatsEvent<any>) => {
        const timeout = 3000
        let elapsed = 0;
        let increment = 10;
        while (true) {
            if (SacaStatsEventUtil.hasCustomEventListener(element, customEvent)) {
                element.dispatchEvent(customEvent);
                return true;
            }

            elapsed += increment;
            if (elapsed >= timeout) {
                SacaStatsEventUtil.logDispatchError(element, customEvent, false);
                element.dispatchEvent(customEvent);
                return false;
            }
            await new Promise(resolve => setTimeout(resolve, 10));
        }
    }

    public static addDocumentCustomEventListener = (customEvent: SacaStatsEvent<any>, callback: Function) => {
        SacaStatsEventUtil.addCustomEventListener(document as any, customEvent, callback);
    };

    public static addCustomEventListener = (element: Element, customEvent: SacaStatsEvent<any>, callback: Function) => {
        if (element != null && typeof (element) != 'undefined' && element.addEventListener) {
            SacaStatsEventUtil.addToElementEventMap(element, customEvent);
            element.addEventListener(customEvent.get(), callback as EventListenerOrEventListenerObject, false);
            return;
        }

        SacaStatsEventUtil.logAddRemoveErrorWithElement(element, customEvent, true);
    };

    public static removeDocumentCustomEventListener = (customEvent: SacaStatsEvent<any>, callback: Function) => {
        SacaStatsEventUtil.removeCustomEventListener(document as any, customEvent, callback);
    };

    public static removeCustomEventListener = (element: Element, customEvent: SacaStatsEvent<any>, callback: Function) => {
        if (element != null && typeof (element) != "undefined") {
            if (!SacaStatsEventUtil.hasCustomEventListener(element, customEvent)) {
                element.removeEventListener(customEvent.get(), callback as EventListenerOrEventListenerObject, false);
                SacaStatsEventUtil.removeFromElementEventMap(element, customEvent);
                return;
            }
        }

        SacaStatsEventUtil.logAddRemoveErrorWithElement(element, customEvent, false);
    };

    private static logAddRemoveErrorWithElement = (element: Element, type: SacaStatsEvent<any>, isAdding: boolean) => {
        console.error("ERROR: Failed to " + ((isAdding) ? "add" : "remove") + " custom listener to element due to error with element for type: '" + type.get() + "' on this element: ", element);
    }

    private static logDispatchError = (element: Element, type: SacaStatsEvent<any>, hasListener: boolean) => {
        if (hasListener) {
            console.error("ERROR: Failed to dispatch custom event to element due to an error with the element for type: '" + type.get() + "' on this element: ", element);
        } else {
            console.log("The event type, '" + type.get() + "' didn't have an event listener on the specified element: ", element);
        }
    }
}


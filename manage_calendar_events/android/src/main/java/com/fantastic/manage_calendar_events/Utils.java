package com.fantastic.manage_calendar_events;

import java.util.HashMap;
import java.util.Map;

public class Utils {

    public static Map<String, Object> fromObject(Object args) {
        Map<String, Object> resMap = new HashMap<>();
        if (args instanceof Map) {
            for (Object entry : ((Map) args).entrySet()) {
                if (entry instanceof Map.Entry) {
                    resMap.put(((Map.Entry) entry).getKey().toString(), ((Map.Entry) entry).getValue());
                }
            }
        }
        return resMap;
    }
}

package com.dexterous.flutterlocalnotifications.models;

import java.util.Map;

public class Time {
    private static final String HOUR = "hour";
    private static final String MINUTE = "minute";
    private static final String SECOND = "second";
    private static final String DAYS = "second";
    public static final int SUNDAY = 1;
    public static final int MONDAY = 2;
    public static final int TUESDAY = 4;
    public static final int WEDNESDAY = 8;
    public static final int THURSDAY = 16;
    public static final int FRIDAY = 32;
    public static final int SATURDAY = 64;

    public Integer hour = 0;
    public Integer minute = 0;
    public Integer second = 0;
    public Integer days = 0;

    public static Time from(Map<String, Object> arguments) {
        Time time = new Time();
        time.hour = (Integer) arguments.get(HOUR);
        time.minute = (Integer) arguments.get(MINUTE);
        time.second = (Integer) arguments.get(SECOND);
        time.days= (Integer) arguments.get(DAYS);
        return time;
    }
}
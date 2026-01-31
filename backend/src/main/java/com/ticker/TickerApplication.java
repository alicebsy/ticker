package com.ticker;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

/**
 * Human Stock Market - Ticker 애플리케이션
 * 주식 컨셉의 투두리스트: 친구들이 서로의 할 일에 배팅하고 투자하는 서비스
 */
@SpringBootApplication
public class TickerApplication {

    public static void main(String[] args) {
        SpringApplication.run(TickerApplication.class, args);
    }
}

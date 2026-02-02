package com.ticker.config;

import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.event.EventListener;
import org.springframework.core.env.Environment;
import org.springframework.stereotype.Component;

/**
 * 애플리케이션 시작 완료 시 안내 메시지 출력
 */
@Component
@Slf4j
public class StartupListener {

    @EventListener(ApplicationReadyEvent.class)
    public void onReady(ApplicationReadyEvent event) {
        Environment env = event.getApplicationContext().getEnvironment();
        String port = env.getProperty("server.port", "8080");

        log.info("===========================================");
        log.info("  Ticker 서버가 시작되었습니다!");
        log.info("  http://localhost:{}/", port);
        log.info("  API: http://localhost:{}/api/portfolio", port);
        log.info("  카카오 로그인: http://localhost:{}/oauth2/authorization/kakao", port);
        log.info("===========================================");
    }
}

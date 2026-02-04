package com.ticker.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

/**
 * 상장(Listing) 화면 API 응답 DTO
 * 내 주가 차트, 상장 중인 종목 목록
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ListingResponse {

    /** 내 주가 차트 데이터 */
    private StockChartDto myStockChart;

    /** 상장 중인 종목 목록 */
    private List<ListedTodoDto> listedTodos;

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class StockChartDto {
        private Long currentPrice;       // 130P
        private String changePercent;    // +3.85%
        private String status;           // "연속 5일 상승"
        private List<ChartPointDto> chartData;  // 1D, 7D, 1M 기간별
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ChartPointDto {
        private String date;
        private Long price;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ListedTodoDto {
        private Long id;
        private String name;           // 헬스장 3회 가기
        private String deadline;       // 2024-02-01
        private Long reward;           // 500P
        private Integer progress;      // 66 (%)
        private Boolean completed;     // 완료 여부
    }
}

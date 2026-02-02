package com.ticker.dto;

import com.ticker.model.Difficulty;
import com.ticker.model.Visibility;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.time.LocalDate;

/**
 * 신규 상장(할 일 등록) 요청 DTO
 */
@Data
public class ListingRequest {

    /** 종목명 (할 일) - 예: "헬스장 주 3회 가기" */
    @NotBlank(message = "종목명을 입력하세요")
    private String name;

    /** 마감일 */
    @NotNull(message = "마감일을 입력하세요")
    private LocalDate deadline;

    /** 공모가 (보상 포인트) - 생략 시 난이도 × (내 주가/100) 자동 계산 */
    private Long rewardPoints;

    /** 난이도 */
    private Difficulty difficulty = Difficulty.NORMAL;

    /** 공개 범위 */
    private Visibility visibility = Visibility.FRIENDS_ONLY;
}

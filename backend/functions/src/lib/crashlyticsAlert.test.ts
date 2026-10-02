import { describe, expect, it } from "vitest";
import {
  CRASHLYTICS_SLACK_CHANNEL,
  formatCrashlyticsAlertText,
} from "./crashlyticsAlert";

/** 本文の組み立てを確かめるための issue。値は Crashlytics の payload の形だけを満たす */
const issue = {
  id: "issue-1",
  title: "Fatal Exception: NSInvalidArgumentException",
  subtitle: "HomePage.swift line 42",
  appVersion: "1.0.0 (1)",
};

describe("formatCrashlyticsAlertText", () => {
  it("投稿先は igen の通知チャンネル", () => {
    expect(CRASHLYTICS_SLACK_CHANNEL).toBe("#igen-notification");
  });

  it("新規 fatal issue は見出し・issue の概要・コンソール URL・分析コマンドを 1 通にまとめる", () => {
    expect(
      formatCrashlyticsAlertText({
        kind: "newFatalIssue",
        projectId: "igen-prod",
        appId: "1:123:ios:abc",
        issue,
      }),
    ).toBe(
      [
        ":rotating_light: Crashlytics 新規の fatal issue: Fatal Exception: NSInvalidArgumentException",
        "HomePage.swift line 42",
        "バージョン 1.0.0 (1) / app 1:123:ios:abc / issue issue-1",
        "https://console.firebase.google.com/project/igen-prod/crashlytics/app/1:123:ios:abc/issues/issue-1",
        "分析: /firebase-crashlytics-triage --app-id 1:123:ios:abc --issue-id issue-1",
      ].join("\n"),
    );
  });

  it("regression と velocity は種別ごとの見出しと補足行を載せる", () => {
    const regression = formatCrashlyticsAlertText({
      kind: "regression",
      projectId: "igen-prod",
      appId: "1:123:ios:abc",
      issue,
      detail: "解決済みだった日時 2026-09-01T00:00:00Z (種別 fatal)",
    });
    expect(regression).toContain(
      ":repeat: Crashlytics regression (解決済み issue の再発)",
    );
    expect(regression).toContain(
      "解決済みだった日時 2026-09-01T00:00:00Z (種別 fatal)",
    );

    const velocity = formatCrashlyticsAlertText({
      kind: "velocity",
      projectId: "igen-prod",
      appId: "1:123:ios:abc",
      issue,
      detail: "crashCount 10 / crashPercentage 1.5 / 初出バージョン 1.0.0",
    });
    expect(velocity).toContain(
      ":chart_with_upwards_trend: Crashlytics velocity alert (クラッシュの急増)",
    );
    expect(velocity).toContain(
      "crashCount 10 / crashPercentage 1.5 / 初出バージョン 1.0.0",
    );
  });
});

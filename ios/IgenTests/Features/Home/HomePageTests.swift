import Testing

@testable import Igen

struct HomePageTests {
  @Test
  func successfulRequestClearsUneditedDraft() {
    #expect(
      HomePage.draftAfterSuccessfulRequest(
        currentDraft: "I feel like I want to die and nothing matters anymore.",
        sentDraft: "I feel like I want to die and nothing matters anymore."
      ) == ""
    )
  }

  @Test
  func successfulRequestPreservesDraftEditedWhileSending() {
    #expect(
      HomePage.draftAfterSuccessfulRequest(
        currentDraft: "A new concern",
        sentDraft: "The concern already sent"
      ) == "A new concern"
    )
  }
}

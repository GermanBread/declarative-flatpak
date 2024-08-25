| BRANCH    | DESCRIPTION                                                                                                                              | SUPPORTED |
|-----------|------------------------------------------------------------------------------------------------------------------------------------------|-----------|
| dev       | Development takes place here                                                                                                             | YES       |
| stable-v1 | The old stable branch before the introduction of resilient updates. It uses a horrible diffing algorithm. Formerly known as "old-stable" | NO        |
| stable-v2 | Former stable branch, but with a separate state directory. Formerly known as the "stable" branch                                         | NO        |
| stable-v3 | Current stable branch                                                                                                                    | YES       |

<small>When a branch gets deprecated you will have to either switch to a newer branch, or revert to the commit before the warning was added.</small>
export type QueuedAnswer = {
  questionId: string;
  answerText?: string;
  optionId?: string;
};

function answerKey(answer: QueuedAnswer) {
  return JSON.stringify(answer);
}

export class AnswerSaveQueue {
  private tail: Promise<unknown> = Promise.resolve();
  private lastKey?: string;

  enqueue(answer: QueuedAnswer, save: (answer: QueuedAnswer) => Promise<unknown>) {
    const key = answerKey(answer);
    if (key === this.lastKey) return this.tail;
    this.lastKey = key;
    const operation = this.tail.catch(() => undefined).then(() => save(answer));
    this.tail = operation.catch((error) => {
      if (this.lastKey === key) this.lastKey = undefined;
      throw error;
    });
    return this.tail;
  }

  pending() {
    return this.tail;
  }
}

export function createAttemptFinalizer(queue: AnswerSaveQueue, submit: () => Promise<unknown>) {
  let finalization: Promise<unknown> | undefined;
  return (dirtyAnswer?: QueuedAnswer, save?: (answer: QueuedAnswer) => Promise<unknown>) => {
    if (finalization) return finalization;
    finalization = (dirtyAnswer && save ? queue.enqueue(dirtyAnswer, save) : queue.pending()).then(submit).catch((error) => {
      finalization = undefined;
      throw error;
    });
    return finalization;
  };
}

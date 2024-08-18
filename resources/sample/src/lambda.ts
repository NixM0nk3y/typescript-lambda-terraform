import type { LambdaInterface } from "@aws-lambda-powertools/commons/types";
import { Context } from "aws-lambda";
import { injectLambdaContext } from "@aws-lambda-powertools/logger/middleware";
import middy from "@middy/core";
import { logger } from "./utils/observability";

class Lambda implements LambdaInterface {
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  public async handler(event: any, context: Context) {
    return {
      result: "hello world!",
    };
  }
}

const handlerClass = new Lambda();

export const lambdaHandler = middy()
  .use(injectLambdaContext(logger, { logEvent: true, clearState: true }))
  .handler(handlerClass.handler);

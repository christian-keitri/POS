declare const _default: () => {
    port: number;
    nodeEnv: string;
    jwt: {
        accessSecret: string;
        refreshSecret: string;
        accessExpiration: string;
        refreshExpiration: string;
    };
    cors: {
        origins: string[];
    };
    throttle: {
        ttl: number;
        limit: number;
    };
    upload: {
        dir: string;
        maxFileSize: number;
    };
};
export default _default;

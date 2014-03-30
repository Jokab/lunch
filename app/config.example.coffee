module.exports = {
    server: {
        ip: '127.0.0.1',
        port: 8080
    },
    database: {
        user: 'postgres',
        database: 'lunch',
        password: '',
        port: 5432,
        host: null,
        ssl: false
    },
    authentication: {
        jwt_secret: "MUCH SECRET. SUCH WOW!"
    }
};
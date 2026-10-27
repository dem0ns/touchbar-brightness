#import <Foundation/Foundation.h>
#import "TBCore.h"

static void usage(void) {
    fputs(
        "tbright — 控制 Touch Bar 亮度（通过环境光传感器注入）\n"
        "\n"
        "用法:\n"
        "  tbright                 显示状态\n"
        "  tbright set <0-100>     按百分比设置（100 = 最亮）\n"
        "  tbright lux <value>     直接指定伪造的环境光 lux 值\n"
        "  tbright up [n]          调亮 n 个百分点（默认 10）\n"
        "  tbright down [n]        调暗 n 个百分点（默认 10）\n"
        "  tbright clear | auto    取消注入，交还真实传感器\n"
        "  tbright restore         重新应用记住的亮度（LaunchAgent 用）\n"
        "  tbright max [n]         查看/设置 lux 上限（默认 5000）\n"
        "  tbright min [n]         查看/设置 lux 下限（默认 1）\n"
        "  tbright help\n"
        "\n"
        "注意：注入的环境光会影响整个系统（主屏自动亮度、键盘背光也会跟着变）。\n",
        stdout);
}

static void printStatus(TBCore *core) {
    if (!core.available) {
        printf("CoreBrightness 不可用\n");
        return;
    }
    double injected = core.overrideLux;
    double real = core.currentLux;
    if (real < 0) real = 0;
    double saved = core.rememberedLux;
    if (injected >= 0) {
        // "Lux" tracks the injected value while the override is active.
        printf("注入中 %.0f lux   范围 %.0f–%.0f lux", injected, core.minLux, core.maxLux);
    } else {
        printf("真实传感器 %.0f lux   范围 %.0f–%.0f lux", real, core.minLux, core.maxLux);
    }
    if (saved >= 0) printf("   记住 %.0f lux", saved);
    printf("\n");
}

static int applyLux(TBCore *core, double lux) {
    [core setLux:lux];
    double now = core.overrideLux;
    if (now >= 0) {
        printf("注入 %.0f lux   (确认成功)\n", now);
        return 0;
    }
    printf("注入 %.0f lux   (失败: 读回 nil)\n", lux);
    return 1;
}

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        setvbuf(stdout, NULL, _IONBF, 0);
        TBCore *core = [TBCore shared];
        NSString *cmd = argc > 1 ? [NSString stringWithUTF8String:argv[1]] : @"get";

        if ([cmd isEqualToString:@"help"] || [cmd isEqualToString:@"-h"] || [cmd isEqualToString:@"--help"]) {
            usage();
            return 0;
        }
        if (!core.available) {
            fprintf(stderr, "错误: 无法加载 BrightnessSystemClient\n");
            return 1;
        }

        if ([cmd isEqualToString:@"get"] || [cmd isEqualToString:@"status"]) {
            printStatus(core);
            return 0;
        }
        if ([cmd isEqualToString:@"set"]) {
            if (argc < 3) { usage(); return 1; }
            double pct = atof(argv[2]);
            if (pct < 0) pct = 0;
            if (pct > 100) pct = 100;
            double lux = [core luxForPercent:pct];
            printf("亮度 %.0f%% → %.0f lux   ", pct, lux);
            return applyLux(core, lux);
        }
        if ([cmd isEqualToString:@"lux"]) {
            if (argc < 3) { printStatus(core); return 0; }
            return applyLux(core, atof(argv[2]));
        }
        if ([cmd isEqualToString:@"up"] || [cmd isEqualToString:@"down"]) {
            double delta = argc > 2 ? atof(argv[2]) : 10.0;
            if (delta < 0) delta = -delta;
            double cur = core.effectiveLux;
            double pct = cur > 0 ? [core percentForLux:cur] : 50;
            pct += [cmd isEqualToString:@"up"] ? delta : -delta;
            if (pct < 0) pct = 0;
            if (pct > 100) pct = 100;
            double lux = [core luxForPercent:pct];
            printf("亮度 %.0f%% → %.0f lux   ", pct, lux);
            return applyLux(core, lux);
        }
        if ([cmd isEqualToString:@"clear"] || [cmd isEqualToString:@"auto"]) {
            [core clearOverride];
            double now = core.overrideLux;
            if (now < 0) {
                printf("已取消注入，交还真实传感器\n");
                return 0;
            }
            printf("取消失败，仍有注入值 %.0f lux\n", now);
            return 1;
        }
        if ([cmd isEqualToString:@"restore"]) {
            double saved = core.rememberedLux;
            BOOL adopt = NO;
            if (saved < 0) {
                saved = core.overrideLux;   // adopt an already-active override
                adopt = YES;
            }
            if (saved < 0) {
                printf("没有记住的亮度值，跳过\n");
                return 0;
            }
            [core restoreRemembered];
            double now = core.overrideLux;
            if (now >= 0) {
                printf("%s %.0f lux (成功)\n", adopt ? "收养并记住" : "恢复", now);
                return 0;
            }
            printf("恢复 %.0f lux (失败)\n", saved);
            return 1;
        }
        if ([cmd isEqualToString:@"max"]) {
            if (argc > 2) core.maxLux = atof(argv[2]);
            printf("max = %.0f lux\n", core.maxLux);
            return 0;
        }
        if ([cmd isEqualToString:@"min"]) {
            if (argc > 2) core.minLux = atof(argv[2]);
            printf("min = %.0f lux\n", core.minLux);
            return 0;
        }

        usage();
        return 1;
    }
}
